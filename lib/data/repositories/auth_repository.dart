import '../models/user.dart';

/// Contrato de autenticación. La UI solo conoce esta interfaz.
///
/// Implementaciones:
/// - `MockAuthRepository`: usuarios guardados en el dispositivo.
/// - `ApiAuthRepository`: endpoints `/auth/*` del backend (pendientes en FastAPI).
abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<void> logout(AuthSession session);
}
