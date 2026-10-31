"""Configuración central del backend (variables de entorno con valores por defecto)."""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


def _env_float(name: str, default: float) -> float:
    return float(os.getenv(name, default))


def _env_int(name: str, default: int) -> int:
    return int(os.getenv(name, default))


@dataclass(frozen=True)
class Settings:
    # --- Modelos (RNF7: se pueden sustituir cambiando la carpeta/archivo) ---
    model_a_dir: Path = field(default_factory=lambda: Path(os.getenv("MODEL_A_DIR", BASE_DIR / "model" / "model_a")))
    model_b_dir: Path = field(default_factory=lambda: Path(os.getenv("MODEL_B_DIR", BASE_DIR / "model" / "model_b")))
    model_c_dir: Path = field(default_factory=lambda: Path(os.getenv("MODEL_C_DIR", BASE_DIR / "model" / "model_c")))
    # Solo para desarrollo/pruebas sin pesos reales. NUNCA en producción.
    use_mock_models: bool = field(default_factory=lambda: os.getenv("USE_MOCK_MODELS", "0") == "1")

    # --- Validación de imágenes (RF3, sección 8.2) ---
    max_image_bytes: int = field(default_factory=lambda: _env_int("MAX_IMAGE_BYTES", 10 * 1024 * 1024))
    min_image_side: int = field(default_factory=lambda: _env_int("MIN_IMAGE_SIDE", 128))
    blur_threshold: float = field(default_factory=lambda: _env_float("BLUR_THRESHOLD", 40.0))
    dark_threshold: float = field(default_factory=lambda: _env_float("DARK_THRESHOLD", 30.0))
    bright_threshold: float = field(default_factory=lambda: _env_float("BRIGHT_THRESHOLD", 235.0))
    allowed_formats: tuple[str, ...] = ("JPEG", "PNG", "WEBP")

    # --- Niveles de confianza (RF9, sección 8.5) ---
    conf_high: float = field(default_factory=lambda: _env_float("CONF_HIGH", 0.85))
    conf_medium: float = field(default_factory=lambda: _env_float("CONF_MEDIUM", 0.65))
    # Por debajo de este valor el resultado se marca como "no concluyente" (RNF10).
    conf_min: float = field(default_factory=lambda: _env_float("CONF_MIN", 0.50))
    # Modelo C: declarar "ausencia de coliformes" exige más confianza que declarar "presencia",
    # porque un falso negativo (decir que el agua está limpia cuando no lo está) es el error peligroso.
    water_absence_min_conf: float = field(default_factory=lambda: _env_float("WATER_ABSENCE_MIN_CONF", 0.75))

    # --- Rendimiento / seguridad ---
    inference_timeout_s: float = field(default_factory=lambda: _env_float("INFERENCE_TIMEOUT_S", 20.0))
    api_key: str | None = field(default_factory=lambda: os.getenv("API_KEY") or None)


def get_settings() -> Settings:
    return Settings()
