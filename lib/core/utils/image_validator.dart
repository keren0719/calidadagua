import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

/// Imagen ya validada y lista para enviarse a la API.
class ValidatedImage {
  const ValidatedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final int width;
  final int height;
}

/// Aplica las mismas reglas del diseño y del backend:
/// JPG o PNG, mínimo 300 × 300 px y máximo 10 MB.
class ImageValidator {
  const ImageValidator._();

  static Future<ValidatedImage> validate(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw const ImageValidationException(
        'No pudimos procesar la imagen. Inténtalo con otro archivo.',
      );
    }
    return validateBytes(bytes, fileName: file.name);
  }

  static Future<ValidatedImage> validateBytes(Uint8List bytes, {required String fileName}) async {
    final mimeType = detectMimeType(bytes);
    if (mimeType == null) {
      throw const ImageValidationException(
        'Formato no compatible. Selecciona una imagen JPG o PNG.',
      );
    }
    if (bytes.lengthInBytes > AppConfig.maxImageBytes) {
      throw const ImageValidationException(
        'La imagen supera el límite de 10 MB. Prueba con una foto más liviana.',
      );
    }

    final int width;
    final int height;
    try {
      // instantiateImageCodec funciona igual en Android, iOS y web.
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      width = frame.image.width;
      height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
    } catch (_) {
      throw const ImageValidationException(
        'No pudimos procesar la imagen. Inténtalo con otro archivo.',
      );
    }

    const min = AppConfig.minImageSide;
    if (width < min || height < min) {
      throw const ImageValidationException(
        'La imagen es demasiado pequeña. Usa una de al menos $min × $min px.',
      );
    }

    return ValidatedImage(
      bytes: bytes,
      fileName: _normalizeName(fileName, mimeType),
      mimeType: mimeType,
      width: width,
      height: height,
    );
  }

  /// Detecta el formato por la firma del archivo (no por la extensión).
  static String? detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return null;
  }

  static String _normalizeName(String name, String mimeType) {
    final ext = mimeType == 'image/png' ? 'png' : 'jpg';
    final base = name.trim().isEmpty ? 'imagen' : name.split(RegExp(r'[\\/]')).last;
    final dot = base.lastIndexOf('.');
    final stem = dot > 0 ? base.substring(0, dot) : base;
    return '$stem.$ext';
  }
}
