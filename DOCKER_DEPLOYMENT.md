# Despliegue de las API con Docker

Cada modelo se ejecuta en su propio contenedor:

| Servicio | URL | Endpoint de predicción |
|---|---|---|
| Pepinos (YOLOv11) | `http://localhost:8001` | `POST /predict/cucumber` |
| Bacterias (EfficientNet) | `http://localhost:8002` | `POST /predict/bacteria` |
| Agua (coliformes) | `http://localhost:8003` | `POST /predict/water` |

La documentación interactiva de cada API está disponible en `/docs`.

## Modelo de agua

Antes de iniciar los contenedores, crea `model/model_c/` y coloca allí:

- `model_c.onnx`
- `classes.json`
- `model_config.json` (opcional si los valores por defecto son adecuados)

El ONNX debe recibir tensores NCHW `float32`; `classes.json` debe identificar al menos dos clases. Si la clase positiva no se puede deducir de sus nombres, define `positive_class` en `model_config.json`. Sin estos archivos el contenedor inicia, pero `/health` muestra `degraded` y las predicciones responden con error de modelo no disponible.

## Iniciar y detener

Desde la carpeta que contiene `compose.yaml`:

```powershell
docker compose up --build -d
docker compose ps
docker compose logs -f
docker compose down
```

Las imágenes de YOLO y EfficientNet usan PyTorch para CPU. El archivo ONNX de pepinos se extrae durante el build desde `yolo11m_cucumber_deployment.zip`; los pesos y la configuración de EfficientNet se copian desde `model/` y `config/`.

Para proteger la API de agua con una clave, define `WATER_API_KEY` antes de levantar Compose. Los clientes deben enviarla en la cabecera `X-API-Key`.