import io
import json
import os
import numpy as np
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image
from ultralytics import YOLO
import torch
import torchvision.transforms as transforms

app = FastAPI(
    title="API Unificada de IA - Cultivos y Bacterias",
    description="Backend en FastAPI para YOLOv11 (Pepinos) y EfficientNet (Bacterias)",
    version="2.0.0",
)


YOLO_MODEL_PATH = "model/yolo11m_cucumber.onnx"

BACTERIA_MODEL_PATH = "model/bacteria_efficientnet_b0_best.pt"
CLASSES_PATH = "model/config/classes.json"
CONFIG_PATH = "model/config/model_config.json"

yolo_model = None
bacteria_model = None
bacteria_classes = []
bacteria_config = {}

@app.on_event("startup")
async def load_all_models_and_configs():
    global yolo_model, bacteria_model, bacteria_classes, bacteria_config
    
    try:
        if os.path.exists(YOLO_MODEL_PATH):
            yolo_model = YOLO(YOLO_MODEL_PATH)
            print("¡Modelo YOLOv11 cargado exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo YOLO en {YOLO_MODEL_PATH}")
    except Exception as e:
        print(f"Error al cargar YOLOv11: {e}")

    try:
        if os.path.exists(CLASSES_PATH):
            with open(CLASSES_PATH, "r", encoding="utf-8") as f:
                bacteria_classes = json.load(f)

        if os.path.exists(CONFIG_PATH):
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                bacteria_config = json.load(f)

        if os.path.exists(BACTERIA_MODEL_PATH):
            bacteria_model = torch.load(BACTERIA_MODEL_PATH, map_location=torch.device("cpu"))
            bacteria_model.eval()
            print("¡Modelo EfficientNet y configuraciones cargados exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo de bacterias en {BACTERIA_MODEL_PATH}")

    except Exception as e:
        print(f"Error al cargar recursos de bacterias: {e}")


@app.get("/")
def read_root():
    return {
        "message": "API de IA para Flutter activa y funcionando",
        "models_loaded": {
            "yolo_cucumber": yolo_model is not None,
            "efficientnet_bacteria": bacteria_model is not None
        }
    }


@app.post("/predict/cucumber")
async def predict_cucumber(file: UploadFile = File(...), conf: float = 0.25, iou: float = 0.45):
    if yolo_model is None:
        raise HTTPException(status_code=500, detail="El modelo YOLO de pepinos no está cargado.")
    
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo enviado no es una imagen válida.")
    
    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_np = np.array(image)
        
        results = yolo_model.predict(
            source=img_np,
            imgsz=640,
            conf=conf,
            iou=iou,
            verbose=False
        )
        
        detections = []
        for result in results:
            if result.boxes is None or len(result.boxes) == 0:
                continue
            
            for box in result.boxes:
                cls_id = int(box.cls.item())
                confidence = float(box.conf.item())
                class_name = result.names[cls_id]
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                
                detections.append({
                    "class_id": cls_id,
                    "class_name": class_name,
                    "confidence": round(confidence, 4),
                    "bbox": {
                        "x1": round(x1, 2),
                        "y1": round(y1, 2),
                        "x2": round(x2, 2),
                        "y2": round(y2, 2)
                    }
                })
                
        return {
            "success": True,
            "total_detections": len(detections),
            "detections": detections
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error procesando imagen en YOLO: {str(e)}")


@app.post("/predict/bacteria")
async def predict_bacteria(file: UploadFile = File(...)):
    if bacteria_model is None:
        raise HTTPException(status_code=500, detail="El modelo EfficientNet de bacterias no está cargado.")

    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo enviado no es una imagen válida.")

    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        img_size = bacteria_config.get("image_size", 224)

        transform = transforms.Compose([
            transforms.Resize((img_size, img_size)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
            ),
        ])

        input_tensor = transform(image).unsqueeze(0)

        with torch.no_grad():
            outputs = bacteria_model(input_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            conf, predicted_idx = torch.max(probabilities, 0)

        predicted_class = (
            bacteria_classes[predicted_idx.item()]
            if bacteria_classes and predicted_idx.item() < len(bacteria_classes)
            else str(predicted_idx.item())
        )
        confidence_score = conf.item()

        return JSONResponse(content={
            "success": True,
            "predicted_class": predicted_class,
            "confidence": round(confidence_score, 4),
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error procesando imagen en EfficientNet: {str(e)}")
