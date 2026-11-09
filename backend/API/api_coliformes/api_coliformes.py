"""Endpoint /predict/water. Se puede montar en la API existente con `app.include_router(router)`
(y `register_error_handlers(app)` + el ciclo de vida de `main.py` para cargar el modelo)."""
from __future__ import annotations

import secrets

from fastapi import APIRouter, FastAPI, File, Header, Request, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import JSONResponse

from . import errors
from .errors import AnalysisError
from .schemas import WaterAnalysisResponse

router = APIRouter(prefix="/predict", tags=["agua (Modelo C)"])

_ERROR_RESPONSES = {
    401: {"description": "API key inválida"},
    413: {"description": "Imagen demasiado grande"},
    415: {"description": "Formato no soportado"},
    422: {"description": "Imagen inválida, pequeña o borrosa"},
    503: {"description": "Modelo no disponible"},
    504: {"description": "Tiempo de inferencia excedido"},
}


@router.post("/water", response_model=WaterAnalysisResponse, responses=_ERROR_RESPONSES)
async def predict_water(
    request: Request,
    file: UploadFile = File(..., description="Imagen de la muestra de agua (JPEG, PNG o WEBP)."),
    x_api_key: str | None = Header(default=None),
) -> WaterAnalysisResponse:
    settings = request.app.state.settings
    if settings.api_key and not (x_api_key and secrets.compare_digest(x_api_key, settings.api_key)):
        raise errors.unauthorized()

    analyzer = getattr(request.app.state, "water_analyzer", None)
    if analyzer is None:
        detail = getattr(request.app.state, "water_error", None)
        raise errors.model_unavailable("Modelo C", detail.message if detail else "")

    # Se lee un byte de más para que la validación detecte el exceso de tamaño sin cargar archivos enormes.
    data = await file.read(settings.max_image_bytes + 1)
    # La imagen se procesa solo en memoria; no se guarda en disco (RNF5).
    return await run_in_threadpool(analyzer.analyze, data)


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AnalysisError)
    async def _analysis_error(_: Request, exc: AnalysisError) -> JSONResponse:  # RF13
        return JSONResponse(status_code=exc.http_status, content={"error": {"code": exc.code, "message": exc.message}})
