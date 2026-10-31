"""Contrato de respuesta del análisis de agua (consumido por la app Flutter)."""
from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field

Label = Literal["presencia", "ausencia", "no_concluyente"]
Level = Literal["alta", "media", "baja"]


class WaterPrediction(BaseModel):
    label: Label = Field(description="Resultado del modelo. 'no_concluyente' si no alcanzó la confianza mínima.")
    leaning: Literal["presencia", "ausencia"] = Field(description="Clase más probable, aunque no sea concluyente.")
    confidence: float = Field(ge=0, le=1, description="Probabilidad de la clase más probable.")
    confidence_level: Level
    probabilities: dict[str, float] = Field(description="Probabilidad por clase (presencia / ausencia).")


class WaterModelInfo(BaseModel):
    name: str
    version: str
    backend: str
    mock: bool = False


class WaterAnalysisResponse(BaseModel):
    analysis: Literal["water"] = "water"
    status: Literal["ok", "inconclusive"]
    prediction: WaterPrediction
    interpretation: str
    recommendations: list[str]
    warnings: list[str] = []
    disclaimer: str
    model: WaterModelInfo
    inference_ms: Optional[float] = None
