import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda las fotos analizadas en el almacenamiento de la app para
/// mostrarlas después en el historial.
class ImageStore {
  const ImageStore();

  /// Devuelve la ruta del archivo o `null` si no se pudo guardar (ej. en web).
  Future<String?> save(String id, Uint8List bytes, {required String extension}) async {
    if (kIsWeb) return null;
    try {
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/analisis');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/$id.$extension');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('No se pudo guardar la imagen del análisis: $e');
      return null;
    }
  }

  Future<void> delete(String? path) async {
    if (kIsWeb || path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
