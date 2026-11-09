"""RF4 – Preprocesamiento. Debe ser IDÉNTICO al usado en el entrenamiento (sección 8.1)."""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from PIL import Image

IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)


@dataclass(frozen=True)
class PreprocessConfig:
    img_size: int = 224
    mean: tuple[float, float, float] = IMAGENET_MEAN
    std: tuple[float, float, float] = IMAGENET_STD

    @classmethod
    def from_dict(cls, d: dict) -> "PreprocessConfig":
        """Lee img_size / mean / std de model_config.json (nombres alternativos tolerados)."""
        size = d.get("img_size") or d.get("image_size") or d.get("input_size") or 224
        if isinstance(size, (list, tuple)):
            size = size[-1]
        return cls(
            img_size=int(size),
            mean=tuple(d.get("mean", IMAGENET_MEAN)),
            std=tuple(d.get("std", IMAGENET_STD)),
        )


def preprocess(image: Image.Image, cfg: PreprocessConfig) -> np.ndarray:
    """RGB PIL -> tensor float32 NCHW normalizado, forma (1, 3, H, W)."""
    img = image.convert("RGB").resize((cfg.img_size, cfg.img_size), Image.BILINEAR)
    arr = np.asarray(img, dtype=np.float32) / 255.0
    arr = (arr - np.array(cfg.mean, dtype=np.float32)) / np.array(cfg.std, dtype=np.float32)
    return np.ascontiguousarray(arr.transpose(2, 0, 1)[None, ...], dtype=np.float32)
