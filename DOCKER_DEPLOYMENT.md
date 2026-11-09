# Despliegue con Docker

Este repositorio despliega la **API FastAPI**, no la app móvil Flutter. Con el Compose base
se habilitan pepinos y bacterias en `http://localhost:8000`. El código del análisis de agua
está incluido, pero sus pesos no están en el repositorio; por eso el servicio puede arrancar
sin ellos y reporta `degraded` en `/health`.

| Endpoint | Modelo |
|---|---|
| `POST /predict/cucumber` | YOLOv11 (pepinos) |
| `POST /predict/bacteria` | EfficientNet-B0 multitarea (Gram + morfología) |
| `POST /predict/water` | Coliformes (agua); requiere los pesos del modelo |
| `GET /health` | Estado de los tres modelos |

Documentación interactiva en `/docs`.

## Iniciar la API

Desde la carpeta que contiene `compose.yaml`:

```bash
docker compose config --quiet
docker compose up --build -d
docker compose ps
docker compose logs -f api
curl http://localhost:${API_PORT:-8000}/health
```

El puerto del host por defecto es `8000`. Si está ocupado o la universidad asignó otro,
puedes elegirlo al iniciar:

```bash
API_PORT=8080 docker compose up --build -d
curl http://localhost:8080/health
```

En un servidor remoto, sustituye `localhost` por su IP o nombre DNS y confirma con
administración de red que el puerto elegido esté permitido desde fuera. Para exponer el
servicio públicamente, configura HTTPS y controles de acceso en un proxy inverso o gateway.

## Modelo de agua

El cargador y el endpoint están en el código, pero los pesos no se distribuyen con el repo.
Cuando estén disponibles, colócalos en `backend/modelos/Bacteria_multitask/model/model_c/`:

- `model_c.onnx`
- `classes.json`
- `model_config.json` (opcional)

Luego inicia incluyendo el Compose opcional, que monta esa carpeta como solo lectura y falla
explícitamente si la carpeta no existe:

```bash
docker compose -f compose.yaml -f compose.water.yaml up --build -d
```

Sin los pesos, el Compose base deja disponibles pepinos y bacterias; `/health` muestra
`degraded` y `/predict/water` responde 503.

## Detener

```bash
docker compose down
```

La variable `API_KEY` protege únicamente `/predict/water` y se envía en la cabecera
`X-API-Key`; no autentica los endpoints de pepinos o bacterias. No publiques esos endpoints
sin controles de acceso de red o un proxy/gateway que los proteja.
