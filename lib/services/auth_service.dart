import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/models/app_error.dart';
import 'package:proballdev/services/auth_storage.dart';
import 'package:proballdev/services/token_store.dart';

/// Handles sign-up, login (JWT), logout, refresh, and load from secure storage.
/// Uses raw HTTP for auth endpoints to avoid circular dependency with ApiClient.
class AuthService {
  AuthService(this._tokenStore, this._authStorage);

  final TokenStore _tokenStore;
  final AuthStorage _authStorage;

  String get _baseUrl {
    final url = AppConstants.apiBaseUrl;
    return url.endsWith('/') ? url : '$url/';
  }

  bool get hasToken => _tokenStore.hasToken;
  String? get userId => _tokenStore.userId;
  String? get userEmail => _tokenStore.userEmail;
  String? get userName => _tokenStore.userName;

  /// Load auth from secure storage into TokenStore. Call on app launch.
  Future<void> loadFromStorage() async {
    final accessToken = await _authStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    final userId = await _authStorage.getUserId();
    final email = await _authStorage.getUserEmail();
    final name = await _authStorage.getUserName();

    await _tokenStore.save(
      accessToken: accessToken,
      userId: userId,
      email: email,
      name: name,
    );
  }

  /// Sign up (one-time). Backend (Better Auth) may return user/token; do not rely on token.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${_baseUrl}api/auth/sign-up/email');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode >= 400) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic>? : null;
      throw AppError.fromApiResponse(body ?? {'code': 'signup_failed', 'message': 'Sign up failed'}, httpStatus: res.statusCode);
    }
  }

  /// Login: get JWT and store token + user info in secure storage and TokenStore.
  Future<void> login({required String email, required String password}) async {
    final uri = Uri.parse('${_baseUrl}api/auth/token');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final resJson = (res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic>? : null) ?? <String, dynamic>{};
    if (resJson['ok'] != true) {
      throw AppError.fromApiResponse(
        resJson.isNotEmpty ? resJson : {'code': 'login_failed', 'message': 'Login failed'},
        httpStatus: res.statusCode,
      );
    }
    final accessToken = resJson['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw AppError(
        type: AppErrorType.unknown,
        severity: AppErrorSeverity.critical,
        userMessage: 'No token received. Please try again.',
      );
    }
    final refreshToken = resJson['refreshToken'] as String?;
    final expiresAtMs = resJson['expiresAtMs'] as int?;
    final user = resJson['user'] as Map<String, dynamic>?;
    final userId = user?['id'] as String?;
    final userEmail = user?['email'] as String? ?? email;
    final userName = user?['name'] as String?;

    // Update in-memory (TokenStore) first so tokenProvider sees new token immediately.
    await _tokenStore.save(
      accessToken: accessToken,
      userId: userId,
      email: userEmail,
      name: userName,
    );
    await _authStorage.save(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtMs: expiresAtMs,
      userId: userId,
      email: userEmail,
      name: userName,
    );
  }

  /// Attempt token refresh. Returns true if new tokens were stored.
  Future<bool> refresh() async {
    final refreshToken = await _authStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final uri = Uri.parse('${_baseUrl}api/auth/refresh');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode != 200) return false;

      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null || json['ok'] != true) return false;

      final accessToken = json['accessToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) return false;

      final newRefreshToken = json['refreshToken'] as String? ?? refreshToken;
      final expiresAtMs = json['expiresAtMs'] as int?;
      final user = json['user'] as Map<String, dynamic>?;

      final userId = user?['id'] as String? ?? _tokenStore.userId;
      final email = user?['email'] as String? ?? _tokenStore.userEmail;
      final name = user?['name'] as String? ?? _tokenStore.userName;

      // Update in-memory (TokenStore) first so tokenProvider sees new token immediately.
      await _tokenStore.save(
        accessToken: accessToken,
        userId: userId,
        email: email,
        name: name,
      );
      await _authStorage.save(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        expiresAtMs: expiresAtMs,
        userId: userId,
        email: email,
        name: name,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Logout: revoke refresh token on server, then clear TokenStore and secure storage.
  Future<void> logout() async {
    final refreshToken = await _authStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final uri = Uri.parse('${_baseUrl}api/auth/logout');
        await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      } catch (_) {
        // Best-effort: continue clearing local state even if server revoke fails.
      }
    }
    await _tokenStore.clear();
    await _authStorage.clear();
  }

  /// Sign in with Google via OAuth webview.
  /// Opens OAuth flow, on success stores JWT and user info.
  Future<void> signInWithGoogle() async {
    final base = _baseUrl.replaceAll(RegExp(r'/$'), '');
    final signInUrl = '$base/oauth/start-google';

    String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: signInUrl,
        callbackUrlScheme: 'proball',
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw AppError(
          type: AppErrorType.unknown,
          severity: AppErrorSeverity.info,
          userMessage: 'Sign in was cancelled.',
        );
      }
      rethrow;
    }

    final uri = Uri.parse(result);
    final accessToken = uri.queryParameters['accessToken'];
    if (accessToken == null || accessToken.isEmpty) {
      throw AppError(
        type: AppErrorType.unknown,
        severity: AppErrorSeverity.critical,
        userMessage: 'Sign in was cancelled or failed.',
      );
    }

    final refreshToken = uri.queryParameters['refreshToken'];
    final expiresAtMs = int.tryParse(uri.queryParameters['expiresAtMs'] ?? '');
    final userId = uri.queryParameters['userId'];
    final userEmail = uri.queryParameters['email'];
    final userName = uri.queryParameters['name'];

    // Update in-memory (TokenStore) first so tokenProvider sees new token immediately.
    await _tokenStore.save(
      accessToken: accessToken,
      userId: userId,
      email: userEmail,
      name: userName,
    );
    await _authStorage.save(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtMs: expiresAtMs,
      userId: userId,
      email: userEmail,
      name: userName,
    );
  }
}
