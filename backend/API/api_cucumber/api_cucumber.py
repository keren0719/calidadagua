import threading
from pathlib import Path

import numpy as np
from fastapi import APIRouter, File, HTTPException, UploadFile
try:
    from ultralytics import YOLO
    ULTRALYTICS_AVAILABLE = True
except ImportError:
    YOLO = None
    ULTRALYTICS_AVAILABLE = False

from api_common import read_image

router = APIRouter()
MODEL_PATH = Path(__file__).parent / "model" / "yolo11m_cucumber.onnx"
yolo_model = None
yolo_lock = threading.Lock()


def load_model() -> None:
    global yolo_model

    if not ULTRALYTICS_AVAILABLE:
        print("Advertencia: Ultralytics no está instalado. Modelo YOLO no cargado.")
        return

    try:
        if MODEL_PATH.exists():
            yolo_model = YOLO(str(MODEL_PATH), task="detect")
            print("¡Modelo YOLOv11 cargado exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo YOLO en {MODEL_PATH}")
    except Exception as exc:
        print(f"Error al cargar YOLOv11: {exc}")


@router.post("/predict/cucumber")
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

    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Error procesando imagen en YOLO: {exc}")
