"""Modelo C – análisis de agua (presencia / ausencia de coliformes). Sección 5.6 del arc42.

Serving con ONNX Runtime (no requiere PyTorch). Para sustituir el modelo (RNF7) basta con
reemplazar los archivos de la carpeta `model/model_c/`:

    model_c.onnx         red exportada (entrada NCHW float32, salida logits o probabilidades)
    classes.json         nombres de clase en el orden de las salidas, p. ej. ["ausencia", "presencia"]
    model_config.json    img_size, mean, std, positive_class (opcional), version (opcional),
                         output_type: "logits" (defecto) | "probabilities"
"""
from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Protocol

import numpy as np

from .. import errors
from ..config import Settings
from ..preprocessing import PreprocessConfig

# Palabras que identifican la clase "sin coliformes" en el nombre de la carpeta/clase.
_NEGATIVE_HINTS = ("aus", "neg", "no_", "no-", "sin", "absen", "limpi", "clean", "safe", "sano")


class WaterModel(Protocol):
    name: str
    version: str
    backend: str
    preprocess_cfg: PreprocessConfig

    def predict(self, x: np.ndarray) -> float:
        """x: (1, 3, H, W) float32 ya preprocesado. Devuelve P(presencia de coliformes) en [0, 1]."""
        ...


# --------------------------------------------------------------------------- utilidades puras
def resolve_positive_index(classes: list[str], positive_class: str | int | None = None) -> int:
    """Índice de la clase 'presencia de coliformes'.

    Prioridad: `positive_class` explícito (nombre o índice) > nombres de clase evidentes.
    Si es ambiguo se falla, en lugar de adivinar: invertir la clase positiva invertiría
    el sentido de todos los resultados.
    """
    if positive_class is not None:
        if isinstance(positive_class, int) or (isinstance(positive_class, str) and positive_class.isdigit()):
            idx = int(positive_class)
            if not 0 <= idx < len(classes):
                raise ValueError(f"positive_class={positive_class} fuera de rango para {classes}")
            return idx
        if positive_class not in classes:
            raise ValueError(f"positive_class '{positive_class}' no está en las clases {classes}")
        return classes.index(positive_class)

    candidates = [i for i, c in enumerate(classes) if not any(h in c.lower() for h in _NEGATIVE_HINTS)]
    if len(candidates) == 1:
        return candidates[0]
    raise ValueError(
        f"No se puede deducir cuál clase significa 'presencia de coliformes' en {classes}. "
        "Defínelo con 'positive_class' en model_config.json."
    )


def to_presence_probability(raw: np.ndarray, n_classes: int, positive_index: int,
                            output_type: str = "logits") -> float:
    """Convierte la salida cruda de la red en P(presencia).

    `output_type` (model_config.json) se declara explícitamente en lugar de adivinarse:
      - "logits" (por defecto, lo que exporta training/train_water.py): softmax, o sigmoide si hay una sola salida.
      - "probabilities": la red ya entrega probabilidades. Una sola salida es P(clase de índice 1).
    """
    if output_type not in ("logits", "probabilities"):
        raise errors.invalid_model_output(f"output_type desconocido: '{output_type}'.")
    v = np.asarray(raw, dtype=np.float64).reshape(-1)
    if not np.all(np.isfinite(v)):
        raise errors.invalid_model_output("la salida contiene NaN o infinitos.")

    if v.size == 1 and n_classes == 2:      # una sola salida = clase de índice 1 (convención BCE)
        z = float(v[0])
        p1 = z if output_type == "probabilities" else 1.0 / (1.0 + math.exp(-max(min(z, 500.0), -500.0)))
        probs = np.array([1.0 - p1, p1])
    elif v.size == n_classes:
        if output_type == "probabilities":
            probs = v
        else:
            e = np.exp(v - v.max())
            probs = e / e.sum()
    else:
        raise errors.invalid_model_output(
            f"se esperaban {n_classes} salidas y el modelo devolvió {v.size}."
        )
    if np.any(probs < -1e-6) or np.any(probs > 1 + 1e-6):
        raise errors.invalid_model_output("las probabilidades están fuera de [0, 1] (¿output_type incorrecto?).")
    return float(np.clip(probs[positive_index], 0.0, 1.0))


def _read_json(path: Path, default):
    if not path.is_file():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise errors.model_unavailable("Modelo C", f"No se pudo leer {path.name}: {exc}")


def _load_classes(path: Path, cfg: dict) -> list[str]:
    data = _read_json(path, None)
    if data is None:
        data = cfg.get("classes")
    if isinstance(data, dict):
        data = data.get("classes", data)
    if isinstance(data, dict):  # {"0": "ausencia", "1": "presencia"}
        data = [v for _, v in sorted(data.items(), key=lambda kv: int(kv[0]))]
    if not isinstance(data, list) or len(data) < 2:
        raise errors.model_unavailable("Modelo C", "classes.json ausente o inválido (se requieren ≥ 2 clases).")
    return [str(c) for c in data]


# --------------------------------------------------------------------------- implementaciones
class OnnxWaterModel:
    backend = "onnxruntime"

    def __init__(self, model_dir: Path):
        model_dir = Path(model_dir)
        if not model_dir.is_dir():
            raise errors.model_unavailable("Modelo C", f"No existe la carpeta {model_dir}.")

        cfg = _read_json(model_dir / "model_config.json", {})
        onnx_path = model_dir / cfg.get("onnx_file", "model_c.onnx")
        if not onnx_path.is_file():
            found = sorted(model_dir.glob("*.onnx"))
            if not found:
                raise errors.model_unavailable("Modelo C", f"No hay ningún archivo .onnx en {model_dir}.")
            onnx_path = found[0]

        self.classes = _load_classes(model_dir / "classes.json", cfg)
        try:
            self.positive_index = resolve_positive_index(self.classes, cfg.get("positive_class"))
        except ValueError as exc:
            raise errors.model_unavailable("Modelo C", str(exc))
        self.preprocess_cfg = PreprocessConfig.from_dict(cfg)
        self.output_type = str(cfg.get("output_type", "logits"))
        self.version = str(cfg.get("version", "desconocida"))
        self.name = "Modelo C – coliformes"

        try:
            import onnxruntime as ort

            self._session = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
        except Exception as exc:  # onnxruntime lanza varios tipos de error
            raise errors.model_unavailable("Modelo C", f"No se pudo cargar {onnx_path.name}: {exc}")
        self._input_name = self._session.get_inputs()[0].name

    def predict(self, x: np.ndarray) -> float:
        out = self._session.run(None, {self._input_name: x})[0]
        return to_presence_probability(out[0], len(self.classes), self.positive_index, self.output_type)


class MockWaterModel:
    """Solo para desarrollo/pruebas sin pesos (USE_MOCK_MODELS=1). Heurística de color: NO es un modelo real."""

    backend = "mock"
    name = "Modelo C (MOCK)"
    version = "mock"

    def __init__(self) -> None:
        self.preprocess_cfg = PreprocessConfig()

    def predict(self, x: np.ndarray) -> float:
        m = x[0].mean(axis=(1, 2))  # medias por canal (normalizadas)
        logit = 3.0 * float(m[0] + m[1] - 2.0 * m[2])
        return float(1.0 / (1.0 + math.exp(-max(min(logit, 50.0), -50.0))))


def load_water_model(settings: Settings) -> WaterModel:
    if settings.use_mock_models:
        return MockWaterModel()
    return OnnxWaterModel(settings.model_c_dir)
