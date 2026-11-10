import io
from fastapi import HTTPException, UploadFile
from PIL import Image, ImageOps

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
MIN_IMAGE_SIDE = 300  # px; igual que la app
ALLOWED_FORMATS = ("JPEG", "PNG")  # igual que la app


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
