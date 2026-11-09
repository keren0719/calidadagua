import io
import json
import threading
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Optional

import numpy as np
import onnxruntime as ort
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ImageOps
from ultralytics import YOLO

# Modelo C (agua / coliformes): aún en desarrollo. Si el paquete `agua` está incompleto
# (p. ej. falta models/water.py), la API arranca igual con YOLO y EfficientNet.
try:
    from agua.api_water import register_error_handlers, router as water_router
    from agua.config import get_settings
    from agua.errors import AnalysisError
    from agua.water_analysis import build_water_analyzer
    WATER_AVAILABLE = True
    WATER_IMPORT_ERROR = None
except Exception as exc:  # ImportError u otro error al importar el paquete
    WATER_AVAILABLE = False
    WATER_IMPORT_ERROR = str(exc)
    print(f"Advertencia: módulo de agua (coliformes) no disponible: {exc}")

# --- CONFIGURACIÓN DE RUTAS (absolutas, no dependen de dónde ejecutes uvicorn) ---
BASE_DIR = Path(__file__).parent
YOLO_MODEL_PATH = BASE_DIR / "model" / "yolo11m_cucumber.onnx"
BACTERIA_MODEL_PATH = BASE_DIR / "model" / "bacteria_efficientnet_b0.onnx"
CLASSES_PATH = BASE_DIR / "model" / "config" / "bacteria_classes.json"
CONFIG_PATH = BASE_DIR / "model" / "config" / "bacteria_model_config.json"

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
MIN_IMAGE_SIDE = 300  # px; igual que la app
ALLOWED_FORMATS = ('JPEG', 'PNG')  # igual que la app

# --- ESTADO GLOBAL ---
yolo_model = None
bacteria_model = None
bacteria_classes = {}  # {'gram': {'0': ...}, 'morphology': {'0': ...}}
bacteria_config = {}

yolo_lock = threading.Lock()


def softmax(logits: np.ndarray) -> np.ndarray:
    z = logits - np.max(logits, axis=1, keepdims=True)
    e = np.exp(z)
    return e / np.sum(e, axis=1, keepdims=True)


def preprocess_bacteria(roi: Image.Image, size: int) -> np.ndarray:
    """Igual que el entrenamiento: RGB, resize, ToTensor y SIN normalización de ImageNet."""
    img = roi.convert("RGB").resize((size, size), Image.BILINEAR)
    arr = np.asarray(img, dtype=np.float32) / 255.0
    return np.ascontiguousarray(arr.transpose(2, 0, 1)[None, ...], dtype=np.float32)


def load_all_models_and_configs():
    global yolo_model, bacteria_model, bacteria_classes, bacteria_config

    # 1. YOLOv11 (ONNX)
    try:
        if YOLO_MODEL_PATH.exists():
            yolo_model = YOLO(str(YOLO_MODEL_PATH), task="detect")
            print("¡Modelo YOLOv11 cargado exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo YOLO en {YOLO_MODEL_PATH}")
    except Exception as e:
        print(f"Error al cargar YOLOv11: {e}")

    # 2. EfficientNet de bacterias
    try:
        if CLASSES_PATH.exists():
            with open(CLASSES_PATH, "r", encoding="utf-8") as f:
                bacteria_classes = json.load(f)

        if CONFIG_PATH.exists():
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                bacteria_config = json.load(f)

        if BACTERIA_MODEL_PATH.exists():
            bacteria_model = ort.InferenceSession(
                str(BACTERIA_MODEL_PATH), providers=["CPUExecutionProvider"]
            )
            print("¡Modelo multitarea de bacterias (ONNX) y configuraciones cargados exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo de bacterias en {BACTERIA_MODEL_PATH}")
    except Exception as e:
        print(f"Error al cargar recursos de bacterias: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    load_all_models_and_configs()

    # Modelo C (agua / coliformes). Si falla, la API sigue viva con los otros modelos:
    # /health informa el problema y /predict/water responde 503.
    app.state.water_analyzer = None
    app.state.water_error = None
    if WATER_AVAILABLE:
        app.state.settings = get_settings()
        try:
            app.state.water_analyzer = build_water_analyzer(app.state.settings)
            print("¡Modelo de agua (coliformes) cargado exitosamente!")
        except AnalysisError as exc:
            app.state.water_error = exc
            print(f"Advertencia: modelo de agua no disponible: {exc.message}")
        except Exception as exc:  # p. ej. faltan los pesos o el cargador
            app.state.water_error = AnalysisError("MODELO_NO_DISPONIBLE", str(exc), 503)
            print(f"Advertencia: modelo de agua no disponible: {exc}")

    yield

    if app.state.water_analyzer is not None:
        app.state.water_analyzer.close()


app = FastAPI(
    title="API Unificada de IA - Cultivos y Bacterias",
    description="Backend en FastAPI para YOLOv11 (pepino) y EfficientNet-B0 multitarea (bacterias: Gram + morfología)",
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
if WATER_AVAILABLE:
    register_error_handlers(app)
    app.include_router(water_router)


def read_image(file: UploadFile) -> Image.Image:
    """Lee el archivo, valida tamaño y formato, y corrige la rotación EXIF."""
    data = file.file.read(MAX_FILE_SIZE + 1)
    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="La imagen supera el límite de 10 MB.")
    try:
        image = Image.open(io.BytesIO(data))
        fmt = image.format
        image.load()
        image = ImageOps.exif_transpose(image)
        image = image.convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="El archivo enviado no es una imagen válida.")
    if fmt not in ALLOWED_FORMATS:
        raise HTTPException(status_code=415, detail="Formato no compatible. Usa una imagen JPG o PNG.")
    if min(image.size) < MIN_IMAGE_SIDE:
        raise HTTPException(
            status_code=422,
            detail=f"La imagen es demasiado pequeña. Usa una de al menos {MIN_IMAGE_SIDE} × {MIN_IMAGE_SIDE} px.",
        )
    return image


@app.get("/")
def read_root():
    return {
        "message": "API de IA para Flutter activa y funcionando",
        "models_loaded": {
            "yolo_cucumber": yolo_model is not None,
            "efficientnet_bacteria": bacteria_model is not None,
            "water_coliforms": getattr(app.state, "water_analyzer", None) is not None,
        },
    }


@app.get("/health")
def health():
    analyzer = getattr(app.state, "water_analyzer", None)
    err = getattr(app.state, "water_error", None)
    models = {
        "yolo_cucumber": yolo_model is not None,
        "efficientnet_bacteria": bacteria_model is not None,
        "water_coliforms": analyzer is not None,
    }
    return {
        "status": "ok" if all(models.values()) else "degraded",
        "models": models,
        "water_model": {
            "loaded": analyzer is not None,
            "backend": analyzer.model.backend if analyzer else None,
            "version": analyzer.model.version if analyzer else None,
            "error": err.message if err else WATER_IMPORT_ERROR,
        },
    }



@app.post("/predict/cucumber")
def predict_cucumber(file: UploadFile = File(...), conf: float = 0.25, iou: float = 0.45):
    if yolo_model is None:
        raise HTTPException(status_code=500, detail="El modelo YOLO de pepinos no está cargado.")

    image = read_image(file)
    width, height = image.size

    try:
        img_np = np.array(image)

        with yolo_lock:
            results = yolo_model.predict(
                source=img_np, imgsz=640, conf=conf, iou=iou, verbose=False
            )

        detections = []
        for result in results:
            if result.boxes is None or len(result.boxes) == 0:
                continue
            for box in result.boxes:
                cls_id = int(box.cls.item())
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                detections.append({
                    "class_id": cls_id,
                    "class_name": result.names[cls_id],
                    "confidence": round(float(box.conf.item()), 4),
                    "bbox": {
                        "x1": round(x1, 2),
                        "y1": round(y1, 2),
                        "x2": round(x2, 2),
                        "y2": round(y2, 2),
                    },
                })

        return {
            "success": True,
            "image_width": width,    
            "image_height": height,
            "total_detections": len(detections),
            "detections": detections,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error procesando imagen en YOLO: {e}")


@app.post("/predict/bacteria")
def predict_bacteria(
    file: UploadFile = File(...),
    x: Optional[int] = None,
    y: Optional[int] = None,
    w: Optional[int] = None,
    h: Optional[int] = None,
):
    """Clasifica una bacteria (Gram + morfología) a partir de un ROI bacteriano.

    El modelo se entrenó con recortes (bbox exacto). Si se envían `x`, `y`, `w`, `h`
    (píxeles de la imagen original) se recorta ese ROI; si no, se usa la imagen completa.
    """
    if bacteria_model is None:
        raise HTTPException(status_code=500, detail="El modelo EfficientNet de bacterias no está cargado.")

    image = read_image(file)

    bbox_given = [v is not None for v in (x, y, w, h)]
    if any(bbox_given):
        if not all(bbox_given):
            raise HTTPException(status_code=422, detail="Para recortar el ROI envía x, y, w y h juntos.")
        if w <= 0 or h <= 0 or x < 0 or y < 0 or x + w > image.width or y + h > image.height:
            raise HTTPException(status_code=422, detail="El ROI queda fuera de la imagen.")
        image = image.crop((x, y, x + w, y + h))

    try:
        size = int((bacteria_config.get("input_size") or [224, 224])[0])
        tensor = preprocess_bacteria(image, size)
        gram_logits, morph_logits = bacteria_model.run(
            ["gram_logits", "morph_logits"], {"image": tensor}
        )
        gram_p = softmax(gram_logits)[0]
        morph_p = softmax(morph_logits)[0]
        gi, mi = int(np.argmax(gram_p)), int(np.argmax(morph_p))
        gram_names = bacteria_classes.get("gram", {})
        morph_names = bacteria_classes.get("morphology", {})
        gram_label = gram_names.get(str(gi), str(gi))
        morph_label = morph_names.get(str(mi), str(mi))

        return {
            "success": True,
            # Campos de compatibilidad con la app actual: la morfología es la clase principal.
            "predicted_class": morph_label,
            "confidence": round(float(morph_p[mi]), 4),
            "gram": {
                "label": gram_label,
                "confidence": round(float(gram_p[gi]), 4),
            },
            "morphology": {
                "label": morph_label,
                "confidence": round(float(morph_p[mi]), 4),
                "probabilities": {
                    morph_names.get(str(k), str(k)): round(float(v), 4) for k, v in enumerate(morph_p)
                },
            },
            "roi_used": any(bbox_given),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error procesando imagen en EfficientNet: {e}")
