import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/mock/mock_data.dart';
import '../data/models/user.dart';
import '../data/repositories/mock_auth_repository.dart';
import 'app_services.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._services);

  final AppServices _services;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;

  AuthStatus get status => _status;
  AppUser? get user => _session?.user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Recupera la sesión guardada al abrir la app.
  Future<void> restore() async {
    _session = _services.session.read();
    _status = _session == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  /// Lanza [AppException] con un mensaje listo para mostrar si falla.
  Future<void> login(String email, String password) async {
    final session = await _services.auth.login(email: email, password: password);
    await _start(session);
  }

  Future<void> register(String name, String email, String password) async {
    final session = await _services.auth.register(name: name, email: email, password: password);
    await _start(session);
  }

  Future<void> requestPasswordReset(String email) => _services.auth.requestPasswordReset(email);

  Future<void> logout() async {
    final session = _session;
    if (session != null) await _services.auth.logout(session);
    await _services.session.clear();
    _session = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _start(AuthSession session) async {
    await _services.session.save(session);
    await _seedDemoHistory(session.user);
    _session = session;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// La cuenta demo arranca con algunos análisis de ejemplo (solo la primera vez).
  Future<void> _seedDemoHistory(AppUser user) async {
    if (user.id != MockAuthRepository.demoUser.id) return;
    const flag = 'history_seeded_demo';
    if (_services.prefs.getBool(flag) == true) return;
    await _services.history.saveAll(user.id, MockData.sampleHistory());
    await _services.prefs.setBool(flag, true);
  }
}
