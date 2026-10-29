import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/app_exception.dart';
import 'image_validator.dart';

/// Abre la cámara o la galería y valida la imagen elegida.
class ImageSourcePicker {
  ImageSourcePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Devuelve `null` si el usuario cancela.
  /// Lanza [ImageValidationException] si la imagen no sirve.
  Future<ValidatedImage?> pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        // Reduce el peso y fuerza JPEG; la API redimensiona a 224/640 px de todos modos.
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
    } on PlatformException catch (e) {
      final denied = e.code.contains('access_denied') || e.code.contains('permission');
      throw ImageValidationException(
        denied
            ? 'No tenemos permiso para usar la ${source == ImageSource.camera ? 'cámara' : 'galería'}. '
                  'Actívalo en los ajustes del teléfono.'
            : 'No pudimos abrir la ${source == ImageSource.camera ? 'cámara' : 'galería'}.',
      );
    }
    if (file == null) return null;
    return ImageValidator.validate(file);
  }
}
