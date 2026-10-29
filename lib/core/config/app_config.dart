/// Configuración global de la app.
///
/// Los valores por defecto se pueden sobreescribir al compilar con
/// `--dart-define`, por ejemplo:
///
/// ```bash
/// flutter run \
///   --dart-define=USE_MOCK_ANALYSIS=false \
///   --dart-define=API_BASE_URL=http://192.168.1.50:8000
/// ```
///
/// Además, desde la pantalla de Configuración se pueden cambiar en caliente
/// (se guardan en el dispositivo y tienen prioridad sobre estos valores).
class AppConfig {
  AppConfig._();

  static const String appName = 'Agrovision AI';
  static const String appVersion = '1.0.0';

  /// `true` = el login/registro usan datos quemados (no llaman al backend).
  static const bool defaultUseMockAuth = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);

  /// `true` = los análisis devuelven resultados simulados (no llaman al backend).
  static const bool defaultUseMockAnalysis = bool.fromEnvironment(
    'USE_MOCK_ANALYSIS',
    defaultValue: true,
  );

  /// URL de la API FastAPI.
  ///
  /// `10.0.2.2` es el "localhost" de tu PC visto desde el emulador de Android.
  /// En un celular físico usa la IP local de tu PC (ej. `http://192.168.1.50:8000`)
  /// y arranca uvicorn con `--host 0.0.0.0`.
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Tiempo máximo de espera de una petición (los modelos pueden tardar).
  static const Duration requestTimeout = Duration(seconds: 60);

  /// Retardo artificial de las respuestas simuladas, para ver los estados de carga.
  static const Duration mockLatency = Duration(milliseconds: 1800);

  // --- Reglas de validación de imagen (iguales a las del backend) ---
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int minImageSide = 300; // px

  // --- Parámetros por defecto de YOLO (/predict/cucumber) ---
  static const double defaultDetectionConfidence = 0.25;
  static const double defaultDetectionIou = 0.45;

  // --- Cuenta demo del modo mock ---
  static const String demoName = 'Keren Saray';
  static const String demoEmail = 'demo@agrovision.ai';
  static const String demoPassword = 'Agro1234';
}
