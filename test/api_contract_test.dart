import 'dart:math';

import 'package:agrovision_ai/data/interpreters/result_interpreter.dart';
import 'package:agrovision_ai/data/mock/mock_data.dart';
import 'package:agrovision_ai/data/models/analysis_result.dart';
import 'package:agrovision_ai/data/models/analysis_type.dart';
import 'package:agrovision_ai/data/models/api_responses.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica que la app entiende EXACTAMENTE el JSON de la API FastAPI
/// y que el mock produce ese mismo formato.
void main() {
  final now = DateTime(2026, 10, 21, 10, 30);

  group('POST /predict/bacteria', () {
    test('parsea la respuesta real de la API', () {
      final p = BacteriaPrediction.fromJson({
        'success': true,
        'predicted_class': 'E_coli',
        'confidence': 0.9312,
      });
      expect(p.success, isTrue);
      expect(p.predictedClass, 'E_coli');
      expect(p.confidence, 0.9312);

      final r = ResultInterpreter.fromBacteria(p, id: '1', createdAt: now);
      expect(r.type, AnalysisType.water);
      expect(r.status, ResultStatus.danger);
      expect(r.title, 'Posible E. coli');
      expect(r.confidencePercent, 93);
    });

    test('agua limpia da el resultado favorable del diseño', () {
      final r = ResultInterpreter.fromBacteria(
        BacteriaPrediction.fromJson({
          'success': true,
          'predicted_class': 'sin_bacterias',
          'confidence': 0.91,
        }),
        id: '1',
        createdAt: now,
      );
      expect(r.status, ResultStatus.good);
      expect(r.title, 'Calidad favorable');
      expect(r.finding, 'Sin anomalías visibles');
    });

    test('una clase desconocida no rompe la app', () {
      final r = ResultInterpreter.fromBacteria(
        BacteriaPrediction.fromJson({
          'success': true,
          'predicted_class': 'Clostridium_perfringens',
          'confidence': 0.7,
        }),
        id: '1',
        createdAt: now,
      );
      expect(r.status, ResultStatus.warning);
      expect(r.title, 'Clostridium perfringens');
      expect(r.recommendations, isNotEmpty);
    });
  });

  group('POST /predict/cucumber', () {
    final apiJson = {
      'success': true,
      'image_width': 1080,
      'image_height': 1440,
      'total_detections': 2,
      'detections': [
        {
          'class_id': 0,
          'class_name': 'healthy',
          'confidence': 0.95,
          'bbox': {'x1': 10.5, 'y1': 20.0, 'x2': 300.25, 'y2': 400.0},
        },
        {
          'class_id': 1,
          'class_name': 'downy_mildew',
          'confidence': 0.81,
          'bbox': {'x1': 400.0, 'y1': 500.0, 'x2': 800.0, 'y2': 900.0},
        },
      ],
    };

    test('parsea la respuesta real de la API', () {
      final p = CucumberPrediction.fromJson(apiJson);
      expect(p.imageWidth, 1080);
      expect(p.imageHeight, 1440);
      expect(p.totalDetections, 2);
      expect(p.detections.first.bbox.x1, 10.5);
      expect(p.toJson()['total_detections'], 2);
    });

    test('prioriza el hallazgo más grave sobre el más confiable', () {
      final r = ResultInterpreter.fromCucumber(
        CucumberPrediction.fromJson(apiJson),
        id: '1',
        createdAt: now,
      );
      expect(r.status, ResultStatus.danger);
      expect(r.title, 'Mildiu velloso');
      expect(r.rawLabel, 'downy_mildew');
      expect(r.detections, hasLength(2));
      expect(r.finding, contains('2 detecciones'));
    });

    test('sin detecciones pide repetir la foto', () {
      final r = ResultInterpreter.fromCucumber(
        CucumberPrediction.fromJson({
          'success': true,
          'image_width': 640,
          'image_height': 640,
          'total_detections': 0,
          'detections': [],
        }),
        id: '1',
        createdAt: now,
      );
      expect(r.title, 'Sin detecciones');
      expect(r.confidence, 0);
    });
  });

  test('GET / (health)', () {
    final h = ApiHealth.fromJson({
      'message': 'API de IA para Flutter activa y funcionando',
      'models_loaded': {'yolo_cucumber': true, 'efficientnet_bacteria': false},
    });
    expect(h.yoloCucumberLoaded, isTrue);
    expect(h.bacteriaLoaded, isFalse);
  });

  group('el mock genera el mismo formato que la API', () {
    test('bacteria', () {
      final random = Random(1);
      for (var i = 0; i < 30; i++) {
        final json = MockData.bacteriaResponse(random);
        expect(json.keys, containsAll(['success', 'predicted_class', 'confidence']));
        final p = BacteriaPrediction.fromJson(json);
        expect(p.confidence, inInclusiveRange(0, 1));
      }
    });

    test('cucumber: cajas dentro de la imagen', () {
      final random = Random(2);
      for (var i = 0; i < 30; i++) {
        final json = MockData.cucumberResponse(random, 1200, 900);
        final p = CucumberPrediction.fromJson(json);
        expect(json['total_detections'], p.detections.length);
        for (final d in p.detections) {
          expect(d.bbox.x1, greaterThanOrEqualTo(0));
          expect(d.bbox.y1, greaterThanOrEqualTo(0));
          expect(d.bbox.x2, lessThanOrEqualTo(1200));
          expect(d.bbox.y2, lessThanOrEqualTo(900));
        }
      }
    });
  });

  test('AnalysisResult sobrevive a guardarse en el historial (toJson/fromJson)', () {
    final original = MockData.sampleHistory().first;
    final copy = AnalysisResult.fromJson(original.toJson());
    expect(copy.id, original.id);
    expect(copy.type, original.type);
    expect(copy.status, original.status);
    expect(copy.title, original.title);
    expect(copy.detections.length, original.detections.length);
    expect(copy.imageUrl, original.imageUrl);
    expect(copy.createdAt, original.createdAt);
  });
}
