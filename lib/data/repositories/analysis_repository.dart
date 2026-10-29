import '../../core/utils/image_validator.dart';
import '../models/analysis_result.dart';
import '../models/analysis_type.dart';
import '../models/api_responses.dart';

/// Contrato de análisis. La UI solo conoce esta interfaz.
///
/// Implementaciones:
/// - `MockAnalysisRepository`: datos quemados, sin red.
/// - `ApiAnalysisRepository`: llama a la API FastAPI real.
abstract class AnalysisRepository {
  Future<AnalysisResult> analyze(AnalysisType type, ValidatedImage image);

  /// `GET /` de la API: indica qué modelos están cargados.
  Future<ApiHealth> checkHealth();
}
