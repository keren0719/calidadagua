import 'api_responses.dart';
import 'analysis_type.dart';

/// Nivel del resultado; define colores e íconos en la pantalla de resultados.
enum ResultStatus {
  good,
  warning,
  danger;

  static ResultStatus fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => ResultStatus.warning);
}

/// Resultado de un análisis ya interpretado para mostrarse en la app.
///
/// Se construye a partir de la respuesta cruda de la API con
/// `ResultInterpreter` y es lo que se guarda en el historial.
class AnalysisResult {
  const AnalysisResult({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.status,
    required this.title,
    required this.finding,
    required this.explanation,
    required this.recommendations,
    required this.confidence,
    required this.rawLabel,
    this.detections = const [],
    this.imageWidth,
    this.imageHeight,
    this.imagePath,
    this.imageUrl,
    this.isSimulated = false,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as String,
      type: AnalysisType.fromId(json['type'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      status: ResultStatus.fromName(json['status'] as String?),
      title: json['title'] as String? ?? '',
      finding: json['finding'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      recommendations: ((json['recommendations'] as List?) ?? const []).cast<String>(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      rawLabel: json['raw_label'] as String? ?? '',
      detections: ((json['detections'] as List?) ?? const [])
          .map((e) => Detection.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      imageWidth: (json['image_width'] as num?)?.toInt(),
      imageHeight: (json['image_height'] as num?)?.toInt(),
      imagePath: json['image_path'] as String?,
      imageUrl: json['image_url'] as String?,
      isSimulated: json['is_simulated'] == true,
    );
  }

  final String id;
  final AnalysisType type;
  final DateTime createdAt;
  final ResultStatus status;

  /// Ej. "Hoja saludable".
  final String title;

  /// Ej. "Sin signos de enfermedad".
  final String finding;
  final String explanation;
  final List<String> recommendations;

  /// Entre 0 y 1.
  final double confidence;

  /// Clase tal cual la devolvió el modelo (ej. `downy_mildew`).
  final String rawLabel;

  /// Solo para planta (YOLO). Coordenadas en píxeles de la imagen original.
  final List<Detection> detections;
  final int? imageWidth;
  final int? imageHeight;

  /// Ruta local de la imagen guardada (historial en el dispositivo).
  final String? imagePath;

  /// Imagen remota (datos de ejemplo del mock o, en el futuro, la API).
  final String? imageUrl;

  /// `true` si el resultado viene del mock y no del modelo real.
  final bool isSimulated;

  int get confidencePercent => (confidence * 100).round();

  AnalysisResult copyWith({String? imagePath, String? imageUrl}) {
    return AnalysisResult(
      id: id,
      type: type,
      createdAt: createdAt,
      status: status,
      title: title,
      finding: finding,
      explanation: explanation,
      recommendations: recommendations,
      confidence: confidence,
      rawLabel: rawLabel,
      detections: detections,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isSimulated: isSimulated,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.id,
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'title': title,
    'finding': finding,
    'explanation': explanation,
    'recommendations': recommendations,
    'confidence': confidence,
    'raw_label': rawLabel,
    'detections': detections.map((d) => d.toJson()).toList(),
    'image_width': imageWidth,
    'image_height': imageHeight,
    'image_path': imagePath,
    'image_url': imageUrl,
    'is_simulated': isSimulated,
  };
}
