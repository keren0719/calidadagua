"""Carga y abstracción del Modelo C (detección de coliformes en agua)."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from ..config import Settings
from ..errors import AnalysisError, model_unavailable
from ..preprocessing import PreprocessConfig


@dataclass
class WaterModel:
    name: str = "water_coliforms"
    version: str = "1.0.0"
    backend: str = "mock"
    preprocess_cfg: PreprocessConfig = field(default_factory=PreprocessConfig)

    def predict(self, x: Any) -> float:
        """Devuelve la probabilidad de presencia de coliformes (entre 0.0 y 1.0)."""
        return 0.0


def load_water_model(settings: Settings) -> WaterModel:
    """Carga el modelo de agua desde settings.model_c_dir o lanza AnalysisError si no está disponible."""
    if settings.use_mock_models:
        return WaterModel(name="water_coliforms_mock", version="0.1.0", backend="mock")

    model_dir = settings.model_c_dir
    candidates = list(model_dir.glob("*.onnx")) + list(model_dir.glob("*.pt")) if model_dir.exists() else []

    if not candidates:
        raise model_unavailable("Modelo C", f"No se encontraron pesos en {model_dir}")

    model_path = candidates[0]
    try:
        import numpy as np
        import onnxruntime as ort

        session = ort.InferenceSession(str(model_path))
        input_name = session.get_inputs()[0].name

        class OnnxWaterModel(WaterModel):
            def predict(self, x: Any) -> float:
                outputs = session.run(None, {input_name: x})
                logits = outputs[0]
                if logits.ndim > 1 and logits.shape[1] > 1:
                    exp = np.exp(logits - np.max(logits, axis=1, keepdims=True))
                    probs = exp / np.sum(exp, axis=1, keepdims=True)
                    return float(probs[0, 1])
                return float(logits.flatten()[0])

        return OnnxWaterModel(name="water_coliforms_onnx", version="1.0.0", backend="onnx")
    except Exception as exc:
        raise model_unavailable("Modelo C", f"Error cargando modelo ONNX en {model_path}: {exc}")
