"""Sistema de recomendación (sección 5.8) para el análisis de agua. Considera el nivel de confianza."""
from __future__ import annotations

from .interpretation import INCONCLUSIVE, NEGATIVE, POSITIVE, WaterDecision

_LAB = (
    "Confirma con un análisis microbiológico de laboratorio (coliformes totales y E. coli) "
    "antes de usar el agua para beber o preparar alimentos."
)
_TREAT = (
    "No consumas esta agua directamente: hiérvela a ebullición vigorosa durante al menos "
    "1 minuto (3 minutos por encima de 2.000 m de altitud) o trátala con un método de desinfección adecuado."
)
_RETAKE = (
    "Vuelve a tomar la foto: buena luz natural, imagen enfocada, la muestra centrada y sobre un fondo "
    "blanco o neutro, sin reflejos."
)


def recommend_water(d: WaterDecision, image_warnings: list[str] | None = None) -> list[str]:
    recs: list[str] = []

    if d.label == POSITIVE:
        recs.append(_TREAT)
        recs.append(_LAB)
        recs.append("Revisa la fuente, el tanque o el recipiente: limpieza, tapa, tuberías y posibles filtraciones.")
        if d.level != "alta":
            recs.append("La confianza no es alta: repite la captura para contrastar el resultado.")
        recs.append(
            "Si hay bebés, personas gestantes, adultos mayores o personas inmunosuprimidas, "
            "extrema las precauciones y consulta a un profesional de salud ante cualquier síntoma."
        )
    elif d.label == NEGATIVE:
        recs.append(_LAB)
        recs.append("Mantén limpios y tapados los recipientes y tanques de almacenamiento.")
        if d.level != "alta":
            recs.append("La confianza no es alta: repite la captura para contrastar el resultado.")
    else:  # no concluyente
        recs.append("No tomes este resultado como señal de que el agua es segura.")
        recs.append(_RETAKE)
        recs.append(_TREAT)
        recs.append(_LAB)

    if image_warnings and d.label != INCONCLUSIVE:
        recs.append(_RETAKE)
    return recs
