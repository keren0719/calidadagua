import '../../core/errors/app_exception.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'auth_repository.dart';

/// Autenticación contra el backend.
///
/// ⚠️ La API FastAPI actual todavía NO tiene estos endpoints. Contrato esperado
/// (ver README → "Contrato de la API"):
///
/// - `POST /auth/login`           `{email, password}`        → `{access_token, token_type, user}`
/// - `POST /auth/register`        `{name, email, password}`  → `{access_token, token_type, user}`
/// - `POST /auth/forgot-password` `{email}`                  → `{message}`
/// - `POST /auth/logout`          (Bearer token)             → `{message}`
///
/// `user` = `{id, name, email, created_at}`.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _guard(() async {
      final json = await _client.postJson('/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      return AuthSession.fromJson(json);
    });
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final json = await _client.postJson('/auth/register', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      return AuthSession.fromJson(json);
    });
  }

  @override
  Future<void> requestPasswordReset(String email) {
    return _guard(
      () => _client.postJson('/auth/forgot-password', {'email': email.trim().toLowerCase()}),
    );
  }

  @override
  Future<void> logout(AuthSession session) async {
    try {
      await _client.postJson('/auth/logout', {});
    } catch (_) {
      // Cerrar sesión localmente aunque el backend no responda.
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        throw const AppException(
          'El backend todavía no tiene endpoints de autenticación. '
          'Activa "Login de prueba" en Configuración para seguir probando.',
          title: 'Autenticación no disponible',
        );
      }
      if (e.statusCode == 401 || e.statusCode == 400) {
        throw AuthException(e.message, statusCode: e.statusCode);
      }
      rethrow;
    } on TypeError {
      throw const AppException('La respuesta del servidor no tiene el formato esperado.');
    }
  }
}
