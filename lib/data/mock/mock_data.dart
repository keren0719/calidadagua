import 'dart:math';

import '../interpreters/result_interpreter.dart';
import '../models/analysis_result.dart';
import '../models/analysis_type.dart';
import '../models/api_responses.dart';

/// Datos quemados para probar la app sin backend.
///
/// Las respuestas tienen exactamente la forma del JSON de la API FastAPI.
class MockData {
  MockData._();

  static const healthResponse = {
    'message': 'API de IA para Flutter activa y funcionando (simulada)',
    'models_loaded': {'yolo_cucumber': true, 'efficientnet_bacteria': true},
  };

  /// Escenarios de agua; los repetidos tienen más probabilidad de salir.
  static const _bacteriaScenarios = [
    ('sin_bacterias', 0.91),
    ('sin_bacterias', 0.88),
    ('sin_bacterias', 0.95),
    ('coliformes', 0.78),
    ('E_coli', 0.86),
    ('Pseudomonas_aeruginosa', 0.64),
  ];

  /// Escenarios de planta.
  static const _cucumberScenarios = [
    ['healthy'],
    ['healthy'],
    ['healthy', 'healthy'],
    ['downy_mildew'],
    ['powdery_mildew', 'healthy'],
    ['anthracnose'],
    <String>[],
  ];

  static const _cucumberClassIds = {
    'healthy': 0,
    'downy_mildew': 1,
    'powdery_mildew': 2,
    'anthracnose': 3,
  };

  /// Mismo formato que `POST /predict/bacteria`.
  static Map<String, dynamic> bacteriaResponse(Random random) {
    final (label, base) = _bacteriaScenarios[random.nextInt(_bacteriaScenarios.length)];
    final confidence = (base + (random.nextDouble() - 0.5) * 0.06).clamp(0.0, 0.99);
    return {
      'success': true,
      'predicted_class': label,
      'confidence': double.parse(confidence.toStringAsFixed(4)),
    };
  }

  /// Mismo formato que `POST /predict/cucumber`.
  static Map<String, dynamic> cucumberResponse(Random random, int width, int height) {
    final labels = _cucumberScenarios[random.nextInt(_cucumberScenarios.length)];
    final detections = <Map<String, dynamic>>[];
    for (var i = 0; i < labels.length; i++) {
      // Cajas razonables dentro de la imagen.
      final w = width * (0.35 + random.nextDouble() * 0.3);
      final h = height * (0.35 + random.nextDouble() * 0.3);
      final x1 = random.nextDouble() * (width - w);
      final y1 = random.nextDouble() * (height - h);
      detections.add({
        'class_id': _cucumberClassIds[labels[i]] ?? 0,
        'class_name': labels[i],
        'confidence': double.parse((0.72 + random.nextDouble() * 0.24).toStringAsFixed(4)),
        'bbox': {
          'x1': double.parse(x1.toStringAsFixed(2)),
          'y1': double.parse(y1.toStringAsFixed(2)),
          'x2': double.parse((x1 + w).toStringAsFixed(2)),
          'y2': double.parse((y1 + h).toStringAsFixed(2)),
        },
      });
    }
    return {
      'success': true,
      'image_width': width,
      'image_height': height,
      'total_detections': detections.length,
      'detections': detections,
    };
  }

  /// Historial de ejemplo para la cuenta demo.
  static List<AnalysisResult> sampleHistory() {
    final now = DateTime.now();
    final plantOk = ResultInterpreter.fromCucumber(
      CucumberPrediction.fromJson({
        'success': true,
        'image_width': 900,
        'image_height': 600,
        'detections': [
          {
            'class_id': 0,
            'class_name': 'healthy',
            'confidence': 0.94,
            'bbox': {'x1': 180.0, 'y1': 90.0, 'x2': 720.0, 'y2': 520.0},
          },
        ],
      }),
      id: 'demo-1',
      createdAt: now.subtract(const Duration(hours: 3)),
      isSimulated: true,
    );
    final water = ResultInterpreter.fromBacteria(
      BacteriaPrediction.fromJson({
        'success': true,
        'predicted_class': 'sin_bacterias',
        'confidence': 0.91,
      }),
      id: 'demo-2',
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      isSimulated: true,
    );
    final plantSick = ResultInterpreter.fromCucumber(
      CucumberPrediction.fromJson({
        'success': true,
        'image_width': 900,
        'image_height': 600,
        'detections': [
          {
            'class_id': 1,
            'class_name': 'downy_mildew',
            'confidence': 0.83,
            'bbox': {'x1': 120.0, 'y1': 140.0, 'x2': 560.0, 'y2': 470.0},
          },
        ],
      }),
      id: 'demo-3',
      createdAt: now.subtract(const Duration(days: 4)),
      isSimulated: true,
    );
    return [
      plantOk.copyWith(imageUrl: AnalysisType.plant.photoUrl),
      water.copyWith(imageUrl: AnalysisType.water.photoUrl),
      plantSick.copyWith(imageUrl: AnalysisType.plant.photoUrl),
    ];
  }
}
