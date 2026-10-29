/// Error con un mensaje listo para mostrar al usuario.
class AppException implements Exception {
  const AppException(this.message, {this.title, this.statusCode, this.cause});

  final String message;
  final String? title;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'AppException($statusCode): $message';
}

/// La imagen no cumple las reglas (formato, tamaño, resolución).
class ImageValidationException extends AppException {
  const ImageValidationException(super.message) : super(title: 'No pudimos usar esta imagen');
}

/// Credenciales inválidas, correo ya registrado, sesión vencida, etc.
class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode});
}
