"""Módulo de interpretación (sección 5.7) para el análisis de agua.

Convierte la salida técnica del modelo en texto comprensible, sin presentarla como diagnóstico definitivo.
"""
from __future__ import annotations

from dataclasses import dataclass

POSITIVE = "presencia"
NEGATIVE = "ausencia"
INCONCLUSIVE = "no_concluyente"

DISCLAIMER = (
    "Este resultado es una estimación automática a partir de una imagen y no reemplaza un análisis "
    "microbiológico de laboratorio. No lo uses como único criterio para decidir si el agua es apta para beber."
)


@dataclass(frozen=True)
class WaterDecision:
    label: str          # presencia | ausencia | no_concluyente
    leaning: str        # clase más probable
    confidence: float   # probabilidad de `leaning`
    level: str          # alta | media | baja
    p_presence: float

    @property
    def conclusive(self) -> bool:
        return self.label != INCONCLUSIVE


def decide(p_presence: float, conf_min: float, conf_medium: float, conf_high: float,
           absence_min_conf: float) -> WaterDecision:
    """Reglas de decisión (RF9, RNF10).

    - 'presencia' si P(presencia) >= 0.5 y la confianza alcanza `conf_min`.
    - 'ausencia' solo si P(ausencia) >= `absence_min_conf` (más exigente: el falso negativo es el error peligroso).
    - En cualquier otro caso: 'no_concluyente'.
    """
    p_absence = 1.0 - p_presence
    if p_presence >= 0.5:
        leaning, conf = POSITIVE, p_presence
        label = POSITIVE if conf >= conf_min else INCONCLUSIVE
    else:
        leaning, conf = NEGATIVE, p_absence
        label = NEGATIVE if conf >= absence_min_conf else INCONCLUSIVE

    level = "alta" if conf >= conf_high else "media" if conf >= conf_medium else "baja"
    return WaterDecision(label, leaning, conf, level, p_presence)


def interpret_water(d: WaterDecision) -> str:
    # Nunca se muestra "100%": el documento (8.5) exige que no se lea como certeza absoluta.
    pct = ">99%" if d.confidence >= 0.995 else f"{d.confidence * 100:.0f}%"
    if d.label == POSITIVE:
        return (
            f"El modelo identifica características visuales compatibles con la presencia de coliformes "
            f"en la muestra, con un nivel de confianza {d.level} ({pct}). "
            "Es una estimación del modelo, no una confirmación de contaminación."
        )
    if d.label == NEGATIVE:
        return (
            f"El modelo no identifica características visuales asociadas a coliformes en la muestra, "
            f"con un nivel de confianza {d.level} ({pct}). Esto no garantiza que el agua sea potable: "
            "una imagen no permite detectar todos los microorganismos ni contaminantes químicos."
        )
    lean = "presencia" if d.leaning == POSITIVE else "ausencia"
    return (
        f"El modelo no alcanzó la confianza necesaria para dar un resultado (inclinación hacia {lean} "
        f"con {pct}). No es posible concluir si hay coliformes y no debe asumirse que el agua es segura."
    )
