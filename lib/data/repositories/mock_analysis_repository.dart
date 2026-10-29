import 'dart:math';

import '../../core/config/app_config.dart';
import '../../core/utils/image_validator.dart';
import '../interpreters/result_interpreter.dart';
import '../mock/mock_data.dart';
import '../models/analysis_result.dart';
import '../models/analysis_type.dart';
import '../models/api_responses.dart';
import 'analysis_repository.dart';

/// Implementación simulada.
///
/// Genera el MISMO JSON que devuelve la API y lo pasa por los mismos
/// `fromJson` + `ResultInterpreter` que la implementación real.
class MockAnalysisRepository implements AnalysisRepository {
  MockAnalysisRepository({Random? random, this.latency = AppConfig.mockLatency})
    : _random = random ?? Random();

  final Random _random;
  final Duration latency;

  @override
  Future<AnalysisResult> analyze(AnalysisType type, ValidatedImage image) async {
    await Future<void>.delayed(latency);

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    switch (type) {
      case AnalysisType.water:
        final json = MockData.bacteriaResponse(_random);
        return ResultInterpreter.fromBacteria(
          BacteriaPrediction.fromJson(json),
          id: id,
          createdAt: now,
          isSimulated: true,
        );
      case AnalysisType.plant:
        final json = MockData.cucumberResponse(_random, image.width, image.height);
        return ResultInterpreter.fromCucumber(
          CucumberPrediction.fromJson(json),
          id: id,
          createdAt: now,
          isSimulated: true,
        );
    }
  }

  @override
  Future<ApiHealth> checkHealth() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return ApiHealth.fromJson(MockData.healthResponse);
  }
}
