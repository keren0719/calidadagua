class AppUser {
  const AppUser({required this.id, required this.name, required this.email, this.createdAt});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: '${json['id']}',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'created_at': createdAt?.toIso8601String(),
  };
}

/// Sesión activa: token + usuario.
class AuthSession {
  const AuthSession({required this.token, required this.user});

  /// Formato esperado del backend (`POST /auth/login`):
  /// `{"access_token": "...", "token_type": "bearer", "user": {...}}`
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['access_token'] as String? ?? '',
    user: AppUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
  );

  final String token;
  final AppUser user;

  Map<String, dynamic> toJson() => {
    'access_token': token,
    'token_type': 'bearer',
    'user': user.toJson(),
  };
}
