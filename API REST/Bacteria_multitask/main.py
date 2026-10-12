import io
import json
import os
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image
import torch
import torchvision.transforms as transforms

app = FastAPI(
    title="API de Predicción de Bacterias",
    description="Backend en FastAPI para clasificar imágenes con EfficientNet",
    version="1.0.0",
)

MODEL_PATH = "model/bacteria_efficientnet_b0_best.pt"
CLASSES_PATH = "model/config/classes.json"
CONFIG_PATH = "model/config/model_config.json"

classes = []
model_config = {}


@app.on_event("startup")
async def load_model_and_configs():
  global model, classes, model_config
  try:
   
    if os.path.exists(CLASSES_PATH):
      with open(CLASSES_PATH, "r", encoding="utf-8") as f:
        classes = json.load(f)

    if os.path.exists(CONFIG_PATH):
      with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        model_config = json.load(f)

   
    if os.path.exists(MODEL_PATH):
      
      model = torch.load(MODEL_PATH, map_location=torch.device("cpu"))
      model.eval()  
      print("¡Modelo y configuraciones cargados exitosamente!")
    else:
      print(f"Advertencia: No se encontró el archivo del modelo en {MODEL_PATH}")

  except Exception as e:
    print(f"Error al cargar recursos: {e}")


@app.get("/")
def read_root():
  return {
      "message": "Bienvenido a la API de clasificación de bacterias de Flutter",
      "status": "activo",
  }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
  if model is None:
    raise HTTPException(
        status_code=500, detail="El modelo no se encuentra cargado en el servidor."
    )

  # Validar que sea una imagen
  if not file.content_type.startswith("image/"):
    raise HTTPException(
        status_code=400, detail="El archivo enviado no es una imagen válida."
    )

  try:
    
    image_bytes = await file.read()
    image = Image.open(io.BytesIO.image_bytes).convert("RGB")

    img_size = model_config.get("image_size", 224)

    
    transform = transforms.Compose([
        transforms.Resize((img_size, img_size)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
        ),
    ])

    input_tensor = transform(image).unsqueeze(
        0
    )  
    
    with torch.no_grad():
      outputs = model(input_tensor)
      probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
      conf, predicted_idx = torch.max(probabilities, 0)

    predicted_class = (
        classes[predicted_idx.item()]
        if classes and predicted_idx.item() < len(classes)
        else str(predicted_idx.item())
    )
    confidence_score = conf.item()

    return JSONResponse(content={
        "success": True,
        "predicted_class": predicted_class,
        "confidence": round(confidence_score, 4),
    })

  except Exception as e:
    raise HTTPException(
        status_code=500, detail=f"Error procesando la imagen: {str(e)}"
    )
