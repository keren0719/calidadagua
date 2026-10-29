import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

/// Preferencias editables desde la pantalla de Configuración.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs)
    : _useMockAuth = _prefs.getBool(_kMockAuth) ?? AppConfig.defaultUseMockAuth,
      _useMockAnalysis = _prefs.getBool(_kMockAnalysis) ?? AppConfig.defaultUseMockAnalysis,
      _apiBaseUrl = _prefs.getString(_kBaseUrl) ?? AppConfig.defaultApiBaseUrl,
      _detectionConfidence = _prefs.getDouble(_kConfidence) ?? AppConfig.defaultDetectionConfidence,
      _saveHistory = _prefs.getBool(_kSaveHistory) ?? true;

  static const _kMockAuth = 'settings_mock_auth';
  static const _kMockAnalysis = 'settings_mock_analysis';
  static const _kBaseUrl = 'settings_api_base_url';
  static const _kConfidence = 'settings_detection_confidence';
  static const _kSaveHistory = 'settings_save_history';

  final SharedPreferences _prefs;

  bool _useMockAuth;
  bool _useMockAnalysis;
  String _apiBaseUrl;
  double _detectionConfidence;
  bool _saveHistory;

  bool get useMockAuth => _useMockAuth;
  bool get useMockAnalysis => _useMockAnalysis;
  String get apiBaseUrl => _apiBaseUrl;
  double get detectionConfidence => _detectionConfidence;
  bool get saveHistory => _saveHistory;

  Future<void> setUseMockAuth(bool value) async {
    _useMockAuth = value;
    notifyListeners();
    await _prefs.setBool(_kMockAuth, value);
  }

  Future<void> setUseMockAnalysis(bool value) async {
    _useMockAnalysis = value;
    notifyListeners();
    await _prefs.setBool(_kMockAnalysis, value);
  }

  Future<void> setApiBaseUrl(String value) async {
    _apiBaseUrl = value.trim();
    notifyListeners();
    await _prefs.setString(_kBaseUrl, _apiBaseUrl);
  }

  Future<void> setDetectionConfidence(double value) async {
    _detectionConfidence = value;
    notifyListeners();
    await _prefs.setDouble(_kConfidence, value);
  }

  Future<void> setSaveHistory(bool value) async {
    _saveHistory = value;
    notifyListeners();
    await _prefs.setBool(_kSaveHistory, value);
  }

  Future<void> resetToDefaults() async {
    for (final key in [_kMockAuth, _kMockAnalysis, _kBaseUrl, _kConfidence, _kSaveHistory]) {
      await _prefs.remove(key);
    }
    _useMockAuth = AppConfig.defaultUseMockAuth;
    _useMockAnalysis = AppConfig.defaultUseMockAnalysis;
    _apiBaseUrl = AppConfig.defaultApiBaseUrl;
    _detectionConfidence = AppConfig.defaultDetectionConfidence;
    _saveHistory = true;
    notifyListeners();
  }
}
