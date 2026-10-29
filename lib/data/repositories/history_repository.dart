import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_result.dart';
import '../services/image_store.dart';

/// Historial de análisis.
///
/// Por ahora se guarda en el dispositivo. Si más adelante el backend expone
/// un `GET /history`, basta con crear otra implementación de esta interfaz.
abstract class HistoryRepository {
  Future<List<AnalysisResult>> getAll(String userId);

  /// Guarda el resultado y (si hay) la imagen; devuelve el resultado con la ruta.
  Future<AnalysisResult> save(
    String userId,
    AnalysisResult result, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  });

  Future<void> saveAll(String userId, List<AnalysisResult> results);

  Future<void> delete(String userId, String id);

  Future<void> clear(String userId);
}

class LocalHistoryRepository implements HistoryRepository {
  LocalHistoryRepository(this._prefs, {ImageStore imageStore = const ImageStore()})
    : _images = imageStore;

  /// Límite para no llenar el almacenamiento del teléfono.
  static const maxItems = 100;

  final SharedPreferences _prefs;
  final ImageStore _images;

  String _key(String userId) => 'history_$userId';

  @override
  Future<List<AnalysisResult>> getAll(String userId) async {
    final raw = _prefs.getStringList(_key(userId)) ?? const [];
    final items = <AnalysisResult>[];
    for (final entry in raw) {
      try {
        items.add(AnalysisResult.fromJson((jsonDecode(entry) as Map).cast<String, dynamic>()));
      } catch (_) {
        // Ignora registros corruptos en vez de romper la pantalla.
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<AnalysisResult> save(
    String userId,
    AnalysisResult result, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    var stored = result;
    if (imageBytes != null) {
      final path = await _images.save(result.id, imageBytes, extension: imageExtension);
      if (path != null) stored = result.copyWith(imagePath: path);
    }

    final items = [stored, ...await getAll(userId)];
    if (items.length > maxItems) {
      for (final old in items.sublist(maxItems)) {
        await _images.delete(old.imagePath);
      }
    }
    await saveAll(userId, items.take(maxItems).toList());
    return stored;
  }

  @override
  Future<void> saveAll(String userId, List<AnalysisResult> results) {
    return _prefs.setStringList(_key(userId), results.map((r) => jsonEncode(r.toJson())).toList());
  }

  @override
  Future<void> delete(String userId, String id) async {
    final items = await getAll(userId);
    for (final item in items.where((r) => r.id == id)) {
      await _images.delete(item.imagePath);
    }
    await saveAll(userId, items.where((r) => r.id != id).toList());
  }

  @override
  Future<void> clear(String userId) async {
    for (final item in await getAll(userId)) {
      await _images.delete(item.imagePath);
    }
    await _prefs.remove(_key(userId));
  }
}
