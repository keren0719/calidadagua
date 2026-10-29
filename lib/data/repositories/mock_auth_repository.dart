import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/user.dart';
import 'auth_repository.dart';

/// Autenticación simulada.
///
/// Siempre existe la cuenta demo ([AppConfig.demoEmail] / [AppConfig.demoPassword]).
/// Las cuentas creadas en "Registro" se guardan en el dispositivo para que
/// puedas volver a iniciar sesión con ellas.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._prefs, {this.latency = const Duration(milliseconds: 900)});

  static const _usersKey = 'mock_users';

  final SharedPreferences _prefs;
  final Duration latency;

  static final demoUser = AppUser(
    id: 'demo',
    name: AppConfig.demoName,
    email: AppConfig.demoEmail,
    createdAt: DateTime(2026, 10, 1),
  );

  Map<String, dynamic> _readUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    await Future<void>.delayed(latency);
    final normalized = email.trim().toLowerCase();

    if (normalized == AppConfig.demoEmail && password == AppConfig.demoPassword) {
      return AuthSession(token: 'mock-token-demo', user: demoUser);
    }

    final record = _readUsers()[normalized] as Map?;
    if (record == null || record['password'] != password) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    final user = AppUser.fromJson((record['user'] as Map).cast<String, dynamic>());
    return AuthSession(token: 'mock-token-${user.id}', user: user);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final normalized = email.trim().toLowerCase();
    final users = _readUsers();

    if (normalized == AppConfig.demoEmail || users.containsKey(normalized)) {
      throw const AuthException('Ya existe una cuenta con este correo.');
    }

    final user = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalized,
      createdAt: DateTime.now(),
    );
    // Solo para pruebas locales: en el backend real la contraseña nunca se guarda así.
    users[normalized] = {'password': password, 'user': user.toJson()};
    await _prefs.setString(_usersKey, jsonEncode(users));
    return AuthSession(token: 'mock-token-${user.id}', user: user);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future<void>.delayed(latency);
  }

  @override
  Future<void> logout(AuthSession session) async {}
}
