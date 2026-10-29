import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';

/// Cliente HTTP mínimo para la API FastAPI.
///
/// Centraliza la URL base, el token, los tiempos de espera y la traducción
/// de errores a mensajes entendibles para el usuario.
class ApiClient {
  ApiClient({
    required String baseUrl,
    this.tokenProvider,
    http.Client? httpClient,
    this.timeout = AppConfig.requestTimeout,
  }) : baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
       _http = httpClient ?? http.Client();

  final String baseUrl;
  final String? Function()? tokenProvider;
  final Duration timeout;
  final http.Client _http;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query.map((k, v) => MapEntry(k, '$v')));
  }

  Map<String, String> get _headers {
    final token = tokenProvider?.call();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query, Duration? timeout}) {
    return _send(() => _http.get(_uri(path, query), headers: _headers), timeout: timeout);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) {
    return _send(
      () => _http.post(
        _uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  /// Envía una imagen como `multipart/form-data` en el campo `file`,
  /// que es lo que esperan `/predict/bacteria` y `/predict/cucumber`.
  Future<Map<String, dynamic>> postImage(
    String path, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    Map<String, dynamic>? query,
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path, query))
        ..headers.addAll(_headers)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      return http.Response.fromStream(await _http.send(request));
    });
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() call, {
    Duration? timeout,
  }) async {
    final http.Response response;
    try {
      response = await call().timeout(timeout ?? this.timeout);
    } on TimeoutException catch (e) {
      throw AppException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
        title: 'Tiempo de espera agotado',
        cause: e,
      );
    } on SocketException catch (e) {
      throw _connectionError(e);
    } on http.ClientException catch (e) {
      throw _connectionError(e);
    }

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // FastAPI devuelve los errores como {"detail": "..."}.
    final detail = body['detail'];
    final message = detail is String && detail.isNotEmpty
        ? detail
        : 'El servidor respondió con un error (${response.statusCode}).';
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(message, statusCode: response.statusCode);
    }
    throw AppException(message, statusCode: response.statusCode);
  }

  AppException _connectionError(Object cause) => AppException(
    'No pudimos conectar con el servidor ($baseUrl). Revisa tu conexión '
    'y la URL de la API en Configuración.',
    title: 'Sin conexión con la API',
    cause: cause,
  );

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } catch (_) {
      return {};
    }
  }

  void close() => _http.close();
}
