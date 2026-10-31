"""RF3 – Validación de imágenes antes del análisis."""
from __future__ import annotations

import io
from dataclasses import dataclass, field

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

from . import errors
from .config import Settings


@dataclass
class ValidatedImage:
    image: Image.Image            # RGB, orientación EXIF corregida
    format: str
    width: int
    height: int
    sharpness: float              # varianza del laplaciano
    brightness: float             # media de gris (0-255)
    warnings: list[str] = field(default_factory=list)


def _laplacian_variance(gray: np.ndarray) -> float:
    """Varianza del laplaciano (medida clásica de nitidez) sin depender de OpenCV."""
    g = gray.astype(np.float32)
    lap = (
        -4.0 * g[1:-1, 1:-1]
        + g[:-2, 1:-1]
        + g[2:, 1:-1]
        + g[1:-1, :-2]
        + g[1:-1, 2:]
    )
    return float(lap.var())


def validate_image(data: bytes, settings: Settings) -> ValidatedImage:
    if not data:
        raise errors.invalid_image("El archivo está vacío.")
    if len(data) > settings.max_image_bytes:
        raise errors.image_too_large(settings.max_image_bytes)

    try:
        with Image.open(io.BytesIO(data)) as probe:
            fmt = probe.format
            probe.verify()  # detecta archivos corruptos
        img = Image.open(io.BytesIO(data))
        img.load()
    except (UnidentifiedImageError, OSError, ValueError, SyntaxError):
        raise errors.invalid_image("El archivo no es una imagen válida o está corrupto.")

    if fmt not in settings.allowed_formats:
        raise errors.unsupported_format(fmt, settings.allowed_formats)

    img = ImageOps.exif_transpose(img).convert("RGB")
    w, h = img.size
    if min(w, h) < settings.min_image_side:
        raise errors.image_too_small(settings.min_image_side)

    # Medidas de calidad sobre una versión reducida (rápido y comparable entre resoluciones).
    small = img.copy()
    small.thumbnail((512, 512))
    gray = np.asarray(small.convert("L"))
    sharpness = _laplacian_variance(gray)
    brightness = float(gray.mean())

    if sharpness < settings.blur_threshold:
        raise errors.image_blurry()

    warnings: list[str] = []
    if brightness < settings.dark_threshold:
        warnings.append("La imagen está muy oscura; el resultado puede ser menos fiable.")
    elif brightness > settings.bright_threshold:
        warnings.append("La imagen está sobreexpuesta; el resultado puede ser menos fiable.")

    return ValidatedImage(img, fmt, w, h, sharpness, brightness, warnings)
