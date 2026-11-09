import contextlib

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from agua.api_water import register_error_handlers, router
from agua.config import get_settings
from agua.errors import AnalysisError
from agua.water_analysis import build_water_analyzer


@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.settings = get_settings()
    app.state.water_analyzer = None
    app.state.water_error = None
    try:
        app.state.water_analyzer = build_water_analyzer(app.state.settings)
    except AnalysisError as exc:
        app.state.water_error = exc
        print(f"Advertencia: modelo de agua no disponible: {exc.message}")

    yield

    if app.state.water_analyzer is not None:
        app.state.water_analyzer.close()


app = FastAPI(title="API de agua - coliformes", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
register_error_handlers(app)
app.include_router(router)


@app.get("/health")
def health():
    analyzer = getattr(app.state, "water_analyzer", None)
    error = getattr(app.state, "water_error", None)
    return {
        "status": "ok" if analyzer is not None else "degraded",
        "model_loaded": analyzer is not None,
        "error": error.message if error else None,
    }