import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../data/repositories/analysis_repository.dart';
import '../data/repositories/api_analysis_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/mock_analysis_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/services/api_client.dart';
import '../data/services/session_storage.dart';
import 'settings_controller.dart';

/// Punto ÚNICO donde se decide si se usan datos simulados o la API real.
///
/// Las pantallas piden `services.analysis` o `services.auth` y no saben
/// qué implementación reciben. Cambiar de mock a API = cambiar el switch
/// en Configuración (o el `--dart-define`), sin tocar ninguna pantalla.
class AppServices {
  AppServices({
    required this.prefs,
    required this.settings,
    AnalysisRepository? mockAnalysis,
    AuthRepository? mockAuth,
    HistoryRepository? history,
  }) : session = SessionStorage(prefs),
       _mockAnalysis = mockAnalysis ?? MockAnalysisRepository(),
       _mockAuth = mockAuth ?? MockAuthRepository(prefs),
       history = history ?? LocalHistoryRepository(prefs);

  final SharedPreferences prefs;
  final SettingsController settings;
  final SessionStorage session;
  final HistoryRepository history;

  final AnalysisRepository _mockAnalysis;
  final AuthRepository _mockAuth;

  ApiClient? _client;

  /// Cliente HTTP; se recrea si cambia la URL en Configuración.
  ApiClient get apiClient {
    final url = settings.apiBaseUrl;
    if (_client == null || _client!.baseUrl != _normalize(url)) {
      _client?.close();
      _client = ApiClient(baseUrl: url, tokenProvider: () => session.read()?.token);
    }
    return _client!;
  }

  AuthRepository get auth => settings.useMockAuth ? _mockAuth : ApiAuthRepository(apiClient);

  AnalysisRepository get analysis => settings.useMockAnalysis
      ? _mockAnalysis
      : ApiAnalysisRepository(
          apiClient,
          detectionConfidence: settings.detectionConfidence,
          detectionIou: AppConfig.defaultDetectionIou,
        );

  /// Repositorio real, aunque el análisis esté en modo mock (para "Probar conexión").
  AnalysisRepository get apiAnalysis => ApiAnalysisRepository(
    apiClient,
    detectionConfidence: settings.detectionConfidence,
    detectionIou: AppConfig.defaultDetectionIou,
  );

  static String _normalize(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
