import '../models/analysis_result.dart';
import '../models/analysis_type.dart';
import '../models/api_responses.dart';
import 'diagnosis_catalog.dart';

/// Convierte la respuesta cruda de la API en un [AnalysisResult] para la UI.
///
/// Lo usan tanto el repositorio real como el mock, así ambos se comportan
/// igual y la UI no se entera de dónde vienen los datos.
class ResultInterpreter {
  const ResultInterpreter._();

  static AnalysisResult fromBacteria(
    BacteriaPrediction prediction, {
    required String id,
    required DateTime createdAt,
    bool isSimulated = false,
  }) {
    final label = prediction.predictedClass;
    final info =
        DiagnosisCatalog.water[DiagnosisCatalog.normalize(label)] ??
        DiagnosisCatalog.waterFallback(label);

    return _build(
      info,
      id: id,
      type: AnalysisType.water,
      createdAt: createdAt,
      confidence: prediction.confidence,
      rawLabel: label,
      isSimulated: isSimulated,
    );
  }

  static AnalysisResult fromCucumber(
    CucumberPrediction prediction, {
    required String id,
    required DateTime createdAt,
    bool isSimulated = false,
  }) {
    if (prediction.detections.isEmpty) {
      return _build(
        DiagnosisCatalog.plantNoDetections,
        id: id,
        type: AnalysisType.plant,
        createdAt: createdAt,
        confidence: 0,
        rawLabel: '',
        imageWidth: prediction.imageWidth,
        imageHeight: prediction.imageHeight,
        isSimulated: isSimulated,
      );
    }

    // Prioriza el hallazgo más grave; ante empate, el de mayor confianza.
    final ranked = [...prediction.detections]
      ..sort((a, b) {
        final severity = _severity(_plantInfo(b.className).status)
            .compareTo(_severity(_plantInfo(a.className).status));
        return severity != 0 ? severity : b.confidence.compareTo(a.confidence);
      });
    final main = ranked.first;
    final info = _plantInfo(main.className);
    final others = ranked.length - 1;

    return _build(
      info,
      id: id,
      type: AnalysisType.plant,
      createdAt: createdAt,
      confidence: main.confidence,
      rawLabel: main.className,
      finding: others > 0 ? '${info.finding} · ${ranked.length} detecciones' : info.finding,
      detections: prediction.detections,
      imageWidth: prediction.imageWidth,
      imageHeight: prediction.imageHeight,
      isSimulated: isSimulated,
    );
  }

  /// Texto bajo el título de la tarjeta de confianza.
  static String confidenceLabel(double confidence) {
    if (confidence >= 0.85) return 'Alta precisión visual';
    if (confidence >= 0.6) return 'Precisión moderada';
    if (confidence > 0) return 'Precisión baja · repite la foto';
    return 'Sin confianza suficiente';
  }

  static DiagnosisInfo _plantInfo(String label) =>
      DiagnosisCatalog.plant[DiagnosisCatalog.normalize(label)] ??
      DiagnosisCatalog.plantFallback(label);

  static int _severity(ResultStatus status) => switch (status) {
    ResultStatus.good => 0,
    ResultStatus.warning => 1,
    ResultStatus.danger => 2,
  };

  static AnalysisResult _build(
    DiagnosisInfo info, {
    required String id,
    required AnalysisType type,
    required DateTime createdAt,
    required double confidence,
    required String rawLabel,
    String? finding,
    List<Detection> detections = const [],
    int? imageWidth,
    int? imageHeight,
    bool isSimulated = false,
  }) {
    return AnalysisResult(
      id: id,
      type: type,
      createdAt: createdAt,
      status: info.status,
      title: info.title,
      finding: finding ?? info.finding,
      explanation: info.explanation,
      recommendations: info.recommendations,
      confidence: confidence.clamp(0, 1).toDouble(),
      rawLabel: rawLabel,
      detections: detections,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      isSimulated: isSimulated,
    );
  }
}
