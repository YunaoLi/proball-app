import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:proballdev/models/app_error.dart';

typedef TokenProvider = String? Function();

/// Callback to attempt token refresh. Returns true if new tokens were stored.
typedef RefreshCallback = Future<bool> Function();

/// Callback when auth fails and we should not redirect (active play).
typedef OnAuthFailureDuringPlay = void Function();

/// Callback when auth fails and we should redirect to login.
typedef OnAuthFailureIdle = void Function();

/// Returns true if user is in active play session (do not redirect on auth failure).
typedef IsPlaySessionActive = bool Function();

/// HTTP client for backend API. Attaches Bearer token for protected endpoints.
/// On 401: attempts refresh once, retries request if successful.
/// If refresh fails: during active play -> set apiDegraded; else -> clear auth and trigger re-login.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    this.refreshCallback,
    this.onAuthFailureDuringPlay,
    this.onAuthFailureIdle,
    this.isPlaySessionActive,
  }) : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  final String baseUrl;
  final TokenProvider tokenProvider;
  final RefreshCallback? refreshCallback;
  final OnAuthFailureDuringPlay? onAuthFailureDuringPlay;
  final OnAuthFailureIdle? onAuthFailureIdle;
  final IsPlaySessionActive? isPlaySessionActive;

  final String _baseUrl;
  bool _refreshAttempted = false;

  String _url(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$_baseUrl$p';
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = false}) async {
    return _executeWithRetry(() => _doGet(path, auth: auth), auth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _executeWithRetry(() => _doPost(path, body: body, auth: auth), auth);
  }

  Future<Map<String, dynamic>> _executeWithRetry(
    Future<http.Response> Function() request,
    bool auth,
  ) async {
    var response = await request();
    if (response.statusCode == 401 && auth && !_refreshAttempted && refreshCallback != null) {
      _refreshAttempted = true;
      final refreshed = await refreshCallback!();
      if (refreshed) {
        response = await request();
      }
      if (response.statusCode == 401) {
        _refreshAttempted = false;
        _handleAuthFailure();
        return _parseJson(response);
      }
      _refreshAttempted = false;
    }
    return _parseJson(response);
  }

  void _handleAuthFailure() {
    final duringPlay = isPlaySessionActive?.call() ?? false;
    if (duringPlay) {
      onAuthFailureDuringPlay?.call();
    } else {
      onAuthFailureIdle?.call();
    }
  }

  Future<http.Response> _doGet(String path, {bool auth = false}) async {
    final uri = Uri.parse(_url(path));
    final headers = _headers(auth: auth);
    return http.get(uri, headers: headers);
  }

  Future<http.Response> _doPost(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse(_url(path));
    final headers = _headers(auth: auth);
    return http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Map<String, String> _headers({bool auth = false}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = tokenProvider();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Map<String, dynamic> _parseJson(http.Response response) {
    if (response.statusCode >= 400) {
      if (response.body.isEmpty) {
        throw AppError.fromHttp(response.statusCode);
      }
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['ok'] == false) {
          throw AppError.fromApiResponse(json, httpStatus: response.statusCode);
        }
      } catch (e) {
        if (e is AppError) rethrow;
        throw AppError.fromHttp(response.statusCode, 'Request failed.');
      }
      throw AppError.fromHttp(response.statusCode);
    }

    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AppError(
        type: AppErrorType.unknown,
        severity: AppErrorSeverity.warning,
        userMessage: 'Invalid response from server.',
      );
    }
  }
}
