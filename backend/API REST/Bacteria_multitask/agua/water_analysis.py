"""Flujo del escenario 2 (sección 6.2/6.3): validación -> preprocesamiento -> inferencia ->
confianza -> interpretación -> recomendación -> respuesta. Independiente del framework web."""
from __future__ import annotations

import time
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import TimeoutError as FutureTimeout

from . import errors
from .config import Settings
from .interpretation import DISCLAIMER, NEGATIVE, POSITIVE, decide, interpret_water
from .models.water import WaterModel, load_water_model
from .preprocessing import preprocess
from .recommendation import recommend_water
from .schemas import WaterAnalysisResponse, WaterModelInfo, WaterPrediction
from .validation import validate_image


class WaterAnalyzer:
    def __init__(self, model: WaterModel, settings: Settings, max_workers: int = 2):
        self.model = model
        self.settings = settings
        self._pool = ThreadPoolExecutor(max_workers=max_workers, thread_name_prefix="water-infer")

    def close(self) -> None:
        self._pool.shutdown(wait=False, cancel_futures=True)

    def analyze(self, data: bytes) -> WaterAnalysisResponse:
        s = self.settings
        validated = validate_image(data, s)                                   # RF3
        x = preprocess(validated.image, self.model.preprocess_cfg)            # RF4

        t0 = time.perf_counter()
        future = self._pool.submit(self.model.predict, x)                     # RF7
        try:
            p_presence = future.result(timeout=s.inference_timeout_s)
        except FutureTimeout:
            future.cancel()
            raise errors.inference_timeout(s.inference_timeout_s)
        elapsed_ms = (time.perf_counter() - t0) * 1000

        d = decide(p_presence, s.conf_min, s.conf_medium, s.conf_high, s.water_absence_min_conf)  # RF8, RF9
        return WaterAnalysisResponse(
            status="ok" if d.conclusive else "inconclusive",
            prediction=WaterPrediction(
                label=d.label,
                leaning=d.leaning,
                confidence=round(d.confidence, 4),
                confidence_level=d.level,
                probabilities={POSITIVE: round(d.p_presence, 4), NEGATIVE: round(1 - d.p_presence, 4)},
            ),
            interpretation=interpret_water(d),                                 # RF10
            recommendations=recommend_water(d, validated.warnings),            # RF11
            warnings=validated.warnings,
            disclaimer=DISCLAIMER,
            model=WaterModelInfo(
                name=self.model.name,
                version=self.model.version,
                backend=self.model.backend,
                mock=self.model.backend == "mock",
            ),
            inference_ms=round(elapsed_ms, 1),
        )


def build_water_analyzer(settings: Settings) -> WaterAnalyzer:
    return WaterAnalyzer(load_water_model(settings), settings)
