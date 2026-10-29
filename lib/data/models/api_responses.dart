/// Modelos que replican EXACTAMENTE el JSON que devuelve la API FastAPI
/// (`API REST/Bacteria_multitask/main.py`). El mock genera estos mismos JSON,
/// así que al conectar la API real no cambia nada en la app.
library;

/// Respuesta de `GET /`.
class ApiHealth {
  const ApiHealth({
    required this.message,
    required this.yoloCucumberLoaded,
    required this.bacteriaLoaded,
  });

  factory ApiHealth.fromJson(Map<String, dynamic> json) {
    final models = (json['models_loaded'] as Map?)?.cast<String, dynamic>() ?? {};
    return ApiHealth(
      message: json['message'] as String? ?? '',
      yoloCucumberLoaded: models['yolo_cucumber'] == true,
      bacteriaLoaded: models['efficientnet_bacteria'] == true,
    );
  }

  final String message;
  final bool yoloCucumberLoaded;
  final bool bacteriaLoaded;
}

/// Respuesta de `POST /predict/bacteria`.
///
/// ```json
/// {"success": true, "predicted_class": "E_coli", "confidence": 0.9312}
/// ```
class BacteriaPrediction {
  const BacteriaPrediction({
    required this.success,
    required this.predictedClass,
    required this.confidence,
  });

  factory BacteriaPrediction.fromJson(Map<String, dynamic> json) {
    return BacteriaPrediction(
      success: json['success'] == true,
      predictedClass: '${json['predicted_class'] ?? ''}',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final bool success;
  final String predictedClass;

  /// Entre 0 y 1.
  final double confidence;

  Map<String, dynamic> toJson() => {
    'success': success,
    'predicted_class': predictedClass,
    'confidence': confidence,
  };
}

/// Caja delimitadora en píxeles de la imagen original.
class BoundingBox {
  const BoundingBox({required this.x1, required this.y1, required this.x2, required this.y2});

  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
    x1: (json['x1'] as num).toDouble(),
    y1: (json['y1'] as num).toDouble(),
    x2: (json['x2'] as num).toDouble(),
    y2: (json['y2'] as num).toDouble(),
  );

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  Map<String, dynamic> toJson() => {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2};
}

/// Un objeto detectado por YOLO.
class Detection {
  const Detection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
    classId: (json['class_id'] as num?)?.toInt() ?? 0,
    className: '${json['class_name'] ?? ''}',
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    bbox: BoundingBox.fromJson((json['bbox'] as Map).cast<String, dynamic>()),
  );

  final int classId;
  final String className;
  final double confidence;
  final BoundingBox bbox;

  Map<String, dynamic> toJson() => {
    'class_id': classId,
    'class_name': className,
    'confidence': confidence,
    'bbox': bbox.toJson(),
  };
}

/// Respuesta de `POST /predict/cucumber`.
///
/// ```json
/// {
///   "success": true, "image_width": 1080, "image_height": 1440,
///   "total_detections": 1,
///   "detections": [{"class_id": 0, "class_name": "healthy", "confidence": 0.91,
///                   "bbox": {"x1": 10.0, "y1": 20.0, "x2": 300.0, "y2": 400.0}}]
/// }
/// ```
class CucumberPrediction {
  const CucumberPrediction({
    required this.success,
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
  });

  factory CucumberPrediction.fromJson(Map<String, dynamic> json) {
    final raw = (json['detections'] as List?) ?? const [];
    return CucumberPrediction(
      success: json['success'] == true,
      imageWidth: (json['image_width'] as num?)?.toInt() ?? 0,
      imageHeight: (json['image_height'] as num?)?.toInt() ?? 0,
      detections: raw.map((e) => Detection.fromJson((e as Map).cast<String, dynamic>())).toList(),
    );
  }

  final bool success;
  final int imageWidth;
  final int imageHeight;
  final List<Detection> detections;

  int get totalDetections => detections.length;

  Map<String, dynamic> toJson() => {
    'success': success,
    'image_width': imageWidth,
    'image_height': imageHeight,
    'total_detections': totalDetections,
    'detections': detections.map((d) => d.toJson()).toList(),
  };
}
