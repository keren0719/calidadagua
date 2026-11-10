import json
from pathlib import Path

try:
    import torch
    import torchvision.transforms as transforms
    from torchvision.models import efficientnet_b0
    TORCH_AVAILABLE = True
except ImportError:
    torch = None
    transforms = None
    efficientnet_b0 = None
    TORCH_AVAILABLE = False
from fastapi import APIRouter, File, HTTPException, UploadFile

from api_common import read_image

router = APIRouter()
BASE_DIR = Path(__file__).parent
MODEL_PATH = BASE_DIR / "model" / "bacteria_efficientnet_b0_best.pt"
CLASSES_PATH = BASE_DIR / "model" / "config" / "classes.json"
CONFIG_PATH = BASE_DIR / "model" / "config" / "model_config.json"

bacteria_model = None
bacteria_classes = []
bacteria_config = {}
bacteria_transform = None


def _load_checkpoint(num_classes: int):
    obj = torch.load(MODEL_PATH, map_location="cpu", weights_only=False)

    if isinstance(obj, torch.nn.Module):
        return obj

    if isinstance(obj, dict):
        state_dict = obj
        for key in ("model_state_dict", "state_dict", "model"):
            if key in obj and isinstance(obj[key], dict):
                state_dict = obj[key]
                break
        state_dict = {key.replace("module.", "", 1): value for key, value in state_dict.items()}
        model = efficientnet_b0(num_classes=num_classes)
        model.load_state_dict(state_dict)
        return model

    raise ValueError(f"Formato de .pt no reconocido: {type(obj)}")


def load_model() -> None:
    global bacteria_model, bacteria_classes, bacteria_config, bacteria_transform

    if not TORCH_AVAILABLE:
        print("Advertencia: PyTorch no está instalado. Modelo de bacterias no cargado.")
        return

    try:
        if CLASSES_PATH.exists():
            with open(CLASSES_PATH, "r", encoding="utf-8") as file:
                bacteria_classes = json.load(file)

        if CONFIG_PATH.exists():
            with open(CONFIG_PATH, "r", encoding="utf-8") as file:
                bacteria_config = json.load(file)

        if MODEL_PATH.exists():
            bacteria_model = _load_checkpoint(num_classes=len(bacteria_classes) or 1000)
            bacteria_model.eval()

            image_size = bacteria_config.get("image_size", 224)
            bacteria_transform = transforms.Compose([
                transforms.Resize((image_size, image_size)),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            ])
            print("¡Modelo EfficientNet y configuraciones cargados exitosamente!")
        else:
            print(f"Advertencia: No se encontró el modelo de bacterias en {MODEL_PATH}")
    except Exception as exc:
        print(f"Error al cargar recursos de bacterias: {exc}")


@router.post("/predict/bacteria")
def predict_bacteria(file: UploadFile = File(...)):
    if bacteria_model is None:
        raise HTTPException(
            status_code=500,
            detail="El modelo EfficientNet de bacterias no está cargado.",
        )

    image = read_image(file)

    try:
        input_tensor = bacteria_transform(image).unsqueeze(0)

        with torch.no_grad():
            outputs = bacteria_model(input_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            confidence, predicted_idx = torch.max(probabilities, 0)

        idx = predicted_idx.item()
        predicted_class = (
            bacteria_classes[idx] if bacteria_classes and idx < len(bacteria_classes) else str(idx)
        )

        return {
            "success": True,
            "predicted_class": predicted_class,
            "confidence": round(confidence.item(), 4),
        }

    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Error procesando imagen en EfficientNet: {exc}",
        )
