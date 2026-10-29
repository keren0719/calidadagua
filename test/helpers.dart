import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:agrovision_ai/app.dart';
import 'package:agrovision_ai/data/repositories/history_repository.dart';
import 'package:agrovision_ai/data/repositories/mock_analysis_repository.dart';
import 'package:agrovision_ai/data/repositories/mock_auth_repository.dart';
import 'package:agrovision_ai/data/services/image_store.dart';
import 'package:agrovision_ai/state/app_services.dart';
import 'package:agrovision_ai/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Genera un PNG real del tamaño indicado (para probar validación y pantallas).
Future<Uint8List> makePng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const Color(0xFF3E8C66),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Servicios con mocks sin latencia y preferencias en memoria.
Future<AppServices> makeServices([Map<String, Object> prefsValues = const {}]) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  return AppServices(
    prefs: prefs,
    settings: SettingsController(prefs),
    mockAuth: MockAuthRepository(prefs, latency: Duration.zero),
    mockAnalysis: MockAnalysisRepository(latency: Duration.zero),
    history: LocalHistoryRepository(prefs, imageStore: const _MemoryImageStore()),
  );
}

/// Evita tocar el sistema de archivos en las pruebas.
class _MemoryImageStore extends ImageStore {
  const _MemoryImageStore();

  @override
  Future<String?> save(String id, Uint8List bytes, {required String extension}) async => null;

  @override
  Future<void> delete(String? path) async {}
}

Widget makeApp(AppServices services) => AgrovisionApp(services: services);
