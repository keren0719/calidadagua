-- =====================================================================
-- AgroVision - Esquema de base de datos (v2)
-- Motor: MariaDB 10.2.1+ (probado para 13.x) | Editor: MySQL Workbench
--
-- Cambios respecto a v1:
--  * Los resultados de los modelos se guardan en una sola tabla
--    "predicciones" (una fila por clase/detección), en vez de columnas y
--    ENUM fijos. Así el esquema sirve aunque se  cambien las clases reales
--    del dataset o el tipo de modelo (clasificación o detección YOLO).
--  * Tabla "modelos": trazabilidad (versión, formato, dataset, licencia).
--  * Estado del análisis (completado / no_concluyente / error).
--  * Retención de imágenes (imagen_eliminada_en).
--
-- =====================================================================

CREATE DATABASE IF NOT EXISTS agrovision_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE agrovision_db;

-- 1. Usuarios ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    correo          VARCHAR(150) NOT NULL,
    contrasena_hash VARCHAR(255) NULL,   -- solo el hash (bcrypt/argon2)
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuarios_correo UNIQUE (correo)
) ENGINE=InnoDB;

-- 2. Modelos (ficha mínima de cada modelo de ML) ----------------------
CREATE TABLE IF NOT EXISTS modelos (
    id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo    VARCHAR(50)  NOT NULL,        -- ej. 'A', 'B', 'C', 'yolo_pepino'
    nombre    VARCHAR(100) NOT NULL,
    tarea     VARCHAR(150) NULL,            -- ej. 'detección de enfermedad en hojas'
    version   VARCHAR(50)  NOT NULL DEFAULT '1.0',
    formato   VARCHAR(30)  NULL,            -- onnx, pt, tflite...
    dataset   VARCHAR(255) NULL,            -- procedencia de los datos
    licencia  VARCHAR(100) NULL,
    activo    BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_modelos_codigo_version UNIQUE (codigo, version)
) ENGINE=InnoDB;

-- 3. Análisis (alimenta la sección "Historial") -----------------------
CREATE TABLE IF NOT EXISTS analisis (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    usuario_id          INT UNSIGNED NULL,   -- NULL = análisis anónimo
    tipo_analisis       ENUM('planta', 'agua') NOT NULL,
    estado              ENUM('completado', 'no_concluyente', 'error')
                        NOT NULL DEFAULT 'completado',
    mensaje_error       VARCHAR(255) NULL,   -- solo si estado = 'error'
    imagen_path         VARCHAR(500) NULL,   -- NULL si la imagen ya fue eliminada
    imagen_eliminada_en DATETIME NULL,       -- política de retención
    fecha_analisis      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_analisis_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_analisis_usuario_fecha (usuario_id, fecha_analisis),
    INDEX idx_analisis_tipo_fecha (tipo_analisis, fecha_analisis)
) ENGINE=InnoDB;

-- 4. Predicciones de los modelos --------------------------------------
-- Una fila por clase predicha o por detección:
--  * Clasificación con una sola clase  -> 1 fila.
--  * Distribución de confianza (ej. Bacteria 86 %, Virus 9 %, Parásito 5 %)
--    -> 1 fila por clase.
--  * Detección tipo YOLO (varias por imagen) -> 1 fila por detección,
--    con la caja (bbox) rellena.
-- La confianza se guarda como porcentaje (0-100); si la API devuelve 0-1,
-- el backend la multiplica por 100 antes de guardarla.
CREATE TABLE IF NOT EXISTS predicciones (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    analisis_id INT UNSIGNED NOT NULL,
    modelo_id   INT UNSIGNED NOT NULL,
    clase       VARCHAR(100) NOT NULL,       -- ej. 'sano', 'E_coli', 'downy_mildew'
    confianza   DECIMAL(5,2) NOT NULL,
    bbox_x1     DECIMAL(8,2) NULL,
    bbox_y1     DECIMAL(8,2) NULL,
    bbox_x2     DECIMAL(8,2) NULL,
    bbox_y2     DECIMAL(8,2) NULL,
    CONSTRAINT fk_pred_analisis
        FOREIGN KEY (analisis_id) REFERENCES analisis(id) ON DELETE CASCADE,
    CONSTRAINT fk_pred_modelo
        FOREIGN KEY (modelo_id) REFERENCES modelos(id),
    CONSTRAINT chk_pred_confianza CHECK (confianza BETWEEN 0 AND 100),
    -- La caja es opcional, pero si existe debe estar completa
    CONSTRAINT chk_pred_bbox CHECK (
        (bbox_x1 IS NULL AND bbox_y1 IS NULL AND bbox_x2 IS NULL AND bbox_y2 IS NULL)
        OR
        (bbox_x1 IS NOT NULL AND bbox_y1 IS NOT NULL
         AND bbox_x2 IS NOT NULL AND bbox_y2 IS NOT NULL)
    ),
    INDEX idx_pred_analisis (analisis_id),
    INDEX idx_pred_modelo_clase (modelo_id, clase)
) ENGINE=InnoDB;

-- 5. Interpretación y recomendaciones ---------------------------------
CREATE TABLE IF NOT EXISTS interpretaciones_recomendaciones (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    analisis_id    INT UNSIGNED NOT NULL,
    interpretacion TEXT NOT NULL,   -- explicación amigable (no es un diagnóstico definitivo)
    recomendacion  TEXT NOT NULL,   -- acciones sugeridas según la confianza
    CONSTRAINT uq_interp_analisis UNIQUE (analisis_id),
    CONSTRAINT fk_interp_analisis
        FOREIGN KEY (analisis_id) REFERENCES analisis(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Vista para la pantalla "Historial" -------------------------------
-- clase_principal = la predicción con mayor confianza (solo titular de la
-- lista; el detalle completo está en la tabla predicciones).
CREATE OR REPLACE VIEW vista_historial AS
SELECT
    a.id AS analisis_id,
    a.usuario_id,
    a.tipo_analisis,
    a.estado,
    a.imagen_path,
    a.fecha_analisis,
    (SELECT p.clase FROM predicciones p
      WHERE p.analisis_id = a.id
      ORDER BY p.confianza DESC, p.id LIMIT 1)      AS clase_principal,
    (SELECT p.confianza FROM predicciones p
      WHERE p.analisis_id = a.id
      ORDER BY p.confianza DESC, p.id LIMIT 1)      AS confianza_principal,
    (SELECT COUNT(*) FROM predicciones p
      WHERE p.analisis_id = a.id)                   AS total_predicciones,
    ir.interpretacion,
    ir.recomendacion
FROM analisis a
LEFT JOIN interpretaciones_recomendaciones ir ON ir.analisis_id = a.id;

-- Ejemplo (comentado) de cómo registrar un modelo cuando exista su ficha:
-- INSERT INTO modelos (codigo, nombre, tarea, version, formato, dataset, licencia)
-- VALUES ('yolo_pepino', 'YOLOv11 pepino', 'detección de enfermedades en pepino',
--         '1.0', 'onnx', 'pendiente', 'pendiente');