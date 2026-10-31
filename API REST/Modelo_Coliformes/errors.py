from __future__ import annotations


class AnalysisError(Exception):
    """Error que impide completar el análisis y que se informa al usuario."""

    def __init__(self, code: str, message: str, http_status: int = 422):
        super().__init__(message)
        self.code = code
        self.message = message
        self.http_status = http_status


def invalid_image(detail: str = "No se pudo leer la imagen.") -> AnalysisError:
    return AnalysisError("IMAGEN_INVALIDA", detail, 422)


def unsupported_format(fmt: str | None, allowed: tuple[str, ...]) -> AnalysisError:
    return AnalysisError(
        "FORMATO_NO_SOPORTADO",
        f"Formato '{fmt}' no soportado. Usa uno de: {', '.join(allowed)}.",
        415,
    )


def image_too_large(max_bytes: int) -> AnalysisError:
    return AnalysisError(
        "IMAGEN_MUY_GRANDE", f"La imagen supera el tamaño máximo de {max_bytes // (1024 * 1024)} MB.", 413
    )


def image_too_small(min_side: int) -> AnalysisError:
    return AnalysisError(
        "IMAGEN_MUY_PEQUENA", f"La imagen es demasiado pequeña (mínimo {min_side}px por lado).", 422
    )


def image_blurry() -> AnalysisError:
    return AnalysisError(
        "IMAGEN_BORROSA",
        "La imagen está borrosa. Enfoca bien y vuelve a capturarla con buena luz.",
        422,
    )


def model_unavailable(name: str, detail: str = "") -> AnalysisError:
    return AnalysisError("MODELO_NO_DISPONIBLE", f"El {name} no está disponible. {detail}".strip(), 503)


def unauthorized() -> AnalysisError:
    return AnalysisError("NO_AUTORIZADO", "API key ausente o inválida.", 401)


def invalid_model_output(detail: str) -> AnalysisError:
    """RNF10: nunca presentar como válido un resultado que no lo es."""
    return AnalysisError("RESULTADO_INVALIDO", f"El modelo produjo una salida no válida: {detail}", 500)


def inference_timeout(seconds: float) -> AnalysisError:
    return AnalysisError(
        "TIEMPO_EXCEDIDO", f"La inferencia superó el tiempo máximo permitido ({seconds:.0f} s).", 504
    )
