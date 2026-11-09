import contextlib

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import api_bacteria
import api_cucumber
from agua.api_water import register_error_handlers, router as water_router
from agua.config import get_settings
from agua.errors import AnalysisError
from agua.water_analysis import build_water_analyzer

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    api_cucumber.load_model()
    api_bacteria.load_model()

    # Modelo C (agua / coliformes). Si falla, la API sigue viva con los otros modelos:
    # /health informa el problema y /predict/water responde 503.
    app.state.settings = get_settings()
    app.state.water_analyzer = None
    app.state.water_error = None
    try:
        app.state.water_analyzer = build_water_analyzer(app.state.settings)
        print("¡Modelo de agua (coliformes) cargado exitosamente!")
    except AnalysisError as exc:
        app.state.water_error = exc
        print(f"Advertencia: modelo de agua no disponible: {exc.message}")

    yield

    if app.state.water_analyzer is not None:
        app.state.water_analyzer.close()


app = FastAPI(
    title="API Unificada de IA - Cultivos y Bacterias",
    description="Backend en FastAPI para YOLOv11 (Pepinos) y EfficientNet (Bacterias)",
    version="2.2.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelo C (agua): endpoint POST /predict/water y errores con formato {"error": {"code", "message"}}.
register_error_handlers(app)
app.include_router(water_router)
app.include_router(api_cucumber.router)
app.include_router(api_bacteria.router)


@app.get("/")
def read_root():
    return {
        "message": "API de IA para Flutter activa y funcionando",
        "models_loaded": {
            "yolo_cucumber": api_cucumber.yolo_model is not None,
            "efficientnet_bacteria": api_bacteria.bacteria_model is not None,
            "water_coliforms": getattr(app.state, "water_analyzer", None) is not None,
        },
    }


@app.get("/health")
def health():
    analyzer = getattr(app.state, "water_analyzer", None)
    err = getattr(app.state, "water_error", None)
    models = {
        "yolo_cucumber": api_cucumber.yolo_model is not None,
        "efficientnet_bacteria": api_bacteria.bacteria_model is not None,
        "water_coliforms": analyzer is not None,
    }
    return {
        "status": "ok" if all(models.values()) else "degraded",
        "models": models,
        "water_model": {
            "loaded": analyzer is not None,
            "backend": analyzer.model.backend if analyzer else None,
            "version": analyzer.model.version if analyzer else None,
            "error": err.message if err else None,
        },
    }
