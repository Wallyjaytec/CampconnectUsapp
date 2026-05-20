import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'login_service.dart';

class ApiService {
  ApiService({GetStorage? storage}) : _box = storage ?? GetStorage();
  final GetStorage _box;

  static bool _isRefreshing = false;
  static Future<bool>? _refreshFuture;

  Map<String, String> _defaultHeaders() {
    final langCode = _box.read<String>(AppConfig.kLangCode) ?? 'en';
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'accept-language': langCode,
    };
    final login = LoginService();
    final token = login.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '${login.tokenType} $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String url, {Map<String, String>? headers}) {
    final uri = Uri.parse(url);
    return _sendWithRefreshRetry(
      builder: () {
        final merged = {..._defaultHeaders(), ...?headers};
        final req = http.Request('GET', uri)..headers.addAll(merged);
        return req;
      },
      tag: 'GET $url',
    );
  }

  Future<Map<String, dynamic>> postJson(
    String url, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    final uri = Uri.parse(url);
    return _sendWithRefreshRetry(
      builder: () {
        final merged = {..._defaultHeaders(), ...?headers};
        final req = http.Request('POST', uri)
          ..headers.addAll(merged)
          ..body = jsonEncode(body ?? const {});
        return req;
      },
      tag: 'POST $url',
    );
  }

  Future<Map<String, dynamic>> putJson(
    String url, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    final uri = Uri.parse(url);
    return _sendWithRefreshRetry(
      builder: () {
        final merged = {..._defaultHeaders(), ...?headers};
        final req = http.Request('PUT', uri)
          ..headers.addAll(merged)
          ..body = jsonEncode(body ?? const {});
        return req;
      },
      tag: 'PUT $url',
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String url, {Map<String, String>? headers}) {
    final uri = Uri.parse(url);
    return _sendWithRefreshRetry(
      builder: () {
        final merged = {..._defaultHeaders(), ...?headers};
        final req = http.Request('DELETE', uri)..headers.addAll(merged);
        return req;
      },
      tag: 'DELETE $url',
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    Map<String, String>? headers,
    List<http.MultipartFile>? files,
  }) {
    final uri = Uri.parse(url);
    return _sendWithRefreshRetry(
      builder: () {
        final merged = {..._defaultHeaders(), ...?headers};
        merged.remove('Content-Type');
        final req = http.MultipartRequest('POST', uri)..headers.addAll(merged);
        req.fields.addAll(fields);
        if (files != null && files.isNotEmpty) {
          req.files.addAll(files);
        }
        return req;
      },
      tag: 'MULTIPART POST $url',
    );
  }

  Future<Map<String, dynamic>> _sendWithRefreshRetry({
    required http.BaseRequest Function() builder,
    required String tag,
  }) async {
    http.Response res = await _dispatch(builder());
    if (res.statusCode == 401) {
      final refreshed = await _refreshTokenOnce();
      if (refreshed) {
        res = await _dispatch(builder());
      }
    }
    return _decodeOrThrow(
      method: (res.request?.method ?? 'HTTP'),
      url: res.request?.url.toString() ?? tag,
      statusCode: res.statusCode,
      body: res.body,
    );
  }

  Future<http.Response> _dispatch(http.BaseRequest req) async {
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return res;
  }

  Future<bool> _refreshTokenOnce() async {
    if (_isRefreshing && _refreshFuture != null) return _refreshFuture!;
    final login = LoginService();
    _isRefreshing = true;
    _refreshFuture = _doRefresh(login);
    final ok = await _refreshFuture!;
    _isRefreshing = false;
    _refreshFuture = null;
    return ok;
  }

  Future<bool> _doRefresh(LoginService login) async {
    try {
      final uri = Uri.parse(AppConfig.customerTokenRefreshUrl());
      final headers = _defaultHeaders();
      final req = http.Request('POST', uri)..headers.addAll(headers);
      final res = await _dispatch(req);
      if (res.statusCode == 401) return false;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiHttpException(
          method: 'POST', url: uri.toString(),
          statusCode: res.statusCode, body: res.body);
      }
      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) return false;
      final success = (decoded['success'] == true) || (decoded['success']?.toString() == 'true');
      final newToken = decoded['access_token']?.toString();
      final tokenType = decoded['token_type']?.toString() ?? 'bearer';
      if (success && (newToken != null && newToken.isNotEmpty)) {
        login.saveToken(newToken, tokenType: tokenType);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeOrThrow({
    required String method, required String url,
    required int statusCode, required String body,
  }) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html>') || trimmed.startsWith('<html')) {
      throw ApiHttpException(method: method, url: url, statusCode: statusCode,
        body: 'HTML received instead of JSON...');
    }
    if (statusCode == 401) {
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic> && decoded['force_logout'] == true) {
          LoginService().logout();
        }
      } catch (_) {}
      try { LoginService().logout(); } catch (_) {}
    }
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiHttpException(method: method, url: url, statusCode: statusCode, body: body);
    }
    try {
      final raw = (body.isEmpty ? '{}' : body);
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (e) {
      throw ApiHttpException(method: method, url: url, statusCode: statusCode,
        body: 'JSON decode failed: $e');
    }
  }

  Future<Map<String, dynamic>> postFormUrlEncodedRaw(
    String url, {required String body, Map<String, String>? headers}) {
    final uri = Uri.parse(url);
    return _sendWithRefreshRetry(
      builder: () {
        final merged = {..._defaultHeaders(), ...?headers};
        merged['Content-Type'] = 'application/x-www-form-urlencoded';
        final req = http.Request('POST', uri)
          ..headers.addAll(merged)
          ..body = body;
        return req;
      },
      tag: 'POST(FORM) $url',
    );
  }
}

class ApiHttpException implements Exception {
  final String method;
  final String url;
  final int statusCode;
  final String body;
  ApiHttpException({
    required this.method, required this.url,
    required this.statusCode, required this.body,
  });
  @override
  String toString() => 'ApiHttpException: $method $url → $statusCode\n$body';
}
