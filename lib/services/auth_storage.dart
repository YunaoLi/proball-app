import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proballdev/core/constants/app_constants.dart';

/// Persists auth state securely via flutter_secure_storage.
/// Stores: accessToken, refreshToken, expiresAt (unix ms), user info.
class AuthStorage {
  AuthStorage() : _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final FlutterSecureStorage _storage;

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.secureAccessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.secureRefreshTokenKey);

  Future<int?> getExpiresAt() async {
    final s = await _storage.read(key: AppConstants.secureExpiresAtKey);
    if (s == null) return null;
    return int.tryParse(s);
  }

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.secureUserIdKey);

  Future<String?> getUserEmail() =>
      _storage.read(key: AppConstants.secureUserEmailKey);

  Future<String?> getUserName() =>
      _storage.read(key: AppConstants.secureUserNameKey);

  /// Returns true if we have a usable access token or a refresh token to try.
  Future<bool> hasValidAuth() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    if (access != null && access.isNotEmpty) {
      final expiresAt = await getExpiresAt();
      if (expiresAt == null) return true;
      // Consider valid if expires in > 60 seconds.
      if (DateTime.now().millisecondsSinceEpoch < (expiresAt - 60 * 1000)) {
        return true;
      }
    }
    return refresh != null && refresh.isNotEmpty;
  }

  /// Returns true if we have any stored auth (token or refresh).
  Future<bool> hasStoredAuth() async {
    final access = await getAccessToken();
    if (access != null && access.isNotEmpty) return true;
    final refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    int? expiresAtMs,
    String? userId,
    String? email,
    String? name,
  }) async {
    await _storage.write(key: AppConstants.secureAccessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: AppConstants.secureRefreshTokenKey, value: refreshToken);
    }
    if (expiresAtMs != null) {
      await _storage.write(key: AppConstants.secureExpiresAtKey, value: expiresAtMs.toString());
    }
    if (userId != null) await _storage.write(key: AppConstants.secureUserIdKey, value: userId);
    if (email != null) await _storage.write(key: AppConstants.secureUserEmailKey, value: email);
    if (name != null) await _storage.write(key: AppConstants.secureUserNameKey, value: name);
  }

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.secureAccessTokenKey);
    await _storage.delete(key: AppConstants.secureRefreshTokenKey);
    await _storage.delete(key: AppConstants.secureExpiresAtKey);
    await _storage.delete(key: AppConstants.secureUserIdKey);
    await _storage.delete(key: AppConstants.secureUserEmailKey);
    await _storage.delete(key: AppConstants.secureUserNameKey);
  }
}
