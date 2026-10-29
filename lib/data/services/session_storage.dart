import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Guarda la sesión en el dispositivo para no pedir login cada vez.
class SessionStorage {
  SessionStorage(this._prefs);

  static const _key = 'auth_session';

  final SharedPreferences _prefs;

  AuthSession? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession session) => _prefs.setString(_key, jsonEncode(session.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}
