import '../../core/errors/app_exception.dart';
import '../../core/utils/image_validator.dart';
import '../interpreters/result_interpreter.dart';
import '../models/analysis_result.dart';
import '../models/analysis_type.dart';
import '../models/api_responses.dart';
import '../services/api_client.dart';
import 'analysis_repository.dart';

/// Implementación real: envía la imagen a la API FastAPI.
class ApiAnalysisRepository implements AnalysisRepository {
  ApiAnalysisRepository(
    this._client, {
    required this.detectionConfidence,
    required this.detectionIou,
  });

  final ApiClient _client;

  /// Parámetros `conf` e `iou` de `/predict/cucumber`.
  final double detectionConfidence;
  final double detectionIou;

  @override
  Future<AnalysisResult> analyze(AnalysisType type, ValidatedImage image) async {
    final json = await _client.postImage(
      type.endpoint,
      bytes: image.bytes,
      fileName: image.fileName,
      mimeType: image.mimeType,
      query: type == AnalysisType.plant ? {'conf': detectionConfidence, 'iou': detectionIou} : null,
    );

    if (json['success'] != true) {
      throw const AppException('La API no pudo analizar la imagen. Inténtalo de nuevo.');
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();
    return switch (type) {
      AnalysisType.water => ResultInterpreter.fromBacteria(
        BacteriaPrediction.fromJson(json),
        id: id,
        createdAt: now,
      ),
      AnalysisType.plant => ResultInterpreter.fromCucumber(
        CucumberPrediction.fromJson(json),
        id: id,
        createdAt: now,
      ),
    };
  }

  @override
  Future<ApiHealth> checkHealth() async =>
      ApiHealth.fromJson(await _client.get('/', timeout: const Duration(seconds: 8)));
}
