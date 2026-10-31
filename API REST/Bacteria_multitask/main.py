import io
import json
import threading
from contextlib import asynccontextmanager
from pathlib import Path

import numpy as np
import torch
import torchvision.transforms as transforms
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ImageOps
from torchvision.models import efficientnet_b0
from ultralytics import YOLO

from agua.api_water import register_error_handlers, router as water_router
from agua.config import get_settings
from agua.errors import AnalysisError
from agua.water_analysis import build_water_analyzer

# --- CONFIGURACIÓN DE RUTAS (absolutas, no dependen de dónde ejecutes uvicorn) ---
BASE_DIR = Path(__file__).parent
YOLO_MODEL_PATH = BASE_DIR / "model" / "yolo11m_cucumber.onnx"
BACTERIA_MODEL_PATH = BASE_DIR / "model" / "bacteria_efficientnet_b0_best.pt"
CLASSES_PATH = BASE_DIR / "model" / "config" / "classes.json"
CONFIG_PATH = BASE_DIR / "model" / "config" / "model_config.json"

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

# --- ESTADO GLOBAL ---
yolo_model = None
bacteria_model = None
bacteria_classes = []
bacteria_config = {}
bacteria_transform = None

yolo_lock = threading.Lock()


def load_bacteria_model(num_classes: int):
    """Carga el .pt sin importar si es modelo completo, state_dict o checkpoint."""

    obj = torch.load(BACTERIA_MODEL_PATH, map_location="cpu", weights_only=False)

  
    if isinstance(obj, torch.nn.Module):
        return obj

    if isinstance(obj, dict):
        state_dict = obj
        for key in ("model_state_dict", "state_dict", "model"):
            if key in obj and isinstance(obj[key], dict):
                state_dict = obj[key]
                break
        state_dict = {k.replace("module.", "", 1): v for k, v in state_dict.items()}
        model = efficientnet_b0(num_classes=num_classes)
        model.load_state_dict(state_dict)
        return model

    raise ValueError(f"Formato de .pt no reconocido: {type(obj)}")


def load_all_models_and_configs():
    global yolo_model, bacteria_model, bacteria_classes, bacteria_config, bacteria_transform

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
            bacteria_model = load_bacteria_model(num_classes=len(bacteria_classes) or 1000)
            bacteria_model.eval()

        
            img_size = bacteria_config.get("image_size", 224)
            bacteria_transform = transforms.Compose([
                transforms.Resize((img_size, img_size)),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            ])
            print("¡Modelo EfficientNet y configuraciones cargados exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo de bacterias en {BACTERIA_MODEL_PATH}")
    except Exception as e:
        print(f"Error al cargar recursos de bacterias: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    load_all_models_and_configs()

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


def read_image(file: UploadFile) -> Image.Image:
    """Lee el archivo, valida tamaño y formato, y corrige la rotación EXIF."""
    data = file.file.read(MAX_FILE_SIZE + 1)
    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="La imagen supera el límite de 10 MB.")
    try:
        image = Image.open(io.BytesIO(data))
        image = ImageOps.exif_transpose(image)  
        return image.convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="El archivo enviado no es una imagen válida.")


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
            "error": err.message if err else None,
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
def predict_bacteria(file: UploadFile = File(...)):
    if bacteria_model is None:
        raise HTTPException(status_code=500, detail="El modelo EfficientNet de bacterias no está cargado.")

    image = read_image(file)

    try:
        input_tensor = bacteria_transform(image).unsqueeze(0)

        with torch.no_grad():
            outputs = bacteria_model(input_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            conf, predicted_idx = torch.max(probabilities, 0)

        idx = predicted_idx.item()
        predicted_class = (
            bacteria_classes[idx] if bacteria_classes and idx < len(bacteria_classes) else str(idx)
        )

        return {
            "success": True,
            "predicted_class": predicted_class,
            "confidence": round(conf.item(), 4),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error procesando imagen en EfficientNet: {e}")
