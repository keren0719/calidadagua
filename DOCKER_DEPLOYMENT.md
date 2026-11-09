# Despliegue con Docker

Un solo contenedor sirve los tres modelos (pepinos, bacterias y agua) en `http://localhost:8000`.

| Endpoint | Modelo |
|---|---|
| `POST /predict/cucumber` | YOLOv11 (pepinos) |
| `POST /predict/bacteria` | EfficientNet-B0 multitarea (Gram + morfología) |
| `POST /predict/water` | Coliformes (agua) |
| `GET /health` | Estado de los tres modelos |

Documentación interactiva en `/docs`.

## Modelo de agua

Coloca los pesos en `backend/modelos/Bacteria_multitask/model/model_c/`:

- `model_c.onnx`
- `classes.json`
- `model_config.json` (opcional)

Sin ellos el contenedor inicia, `/health` muestra `degraded` y `/predict/water` responde 503.

## Iniciar y detener

Desde la carpeta que contiene `compose.yaml`:

```bash
docker compose up --build -d
docker compose ps
docker compose logs -f
docker compose down
```

Para proteger `/predict/water` con una clave, define `API_KEY` antes de levantar Compose
y envíala en la cabecera `X-API-Key`.
