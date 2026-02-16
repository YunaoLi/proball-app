/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Wicked Rolling Ball Pro';
  static const String appTagline = 'AI-Powered Pet Play';

  /// Backend API base URL. Override for debug/staging.
  static const String apiBaseUrl = 'https://proball-app.vercel.app';

  /// SharedPreferences keys for auth (legacy; prefer AuthStorage).
  static const String tokenStorageKey = 'auth_access_token';
  static const String userIdStorageKey = 'auth_user_id';
  static const String userEmailStorageKey = 'auth_user_email';
  static const String userNameStorageKey = 'auth_user_name';
  static const String pairedDeviceIdKey = 'paired_device_id';

  /// When true, mock BLE scan emits 0–2 nearby devices. When false, scan is empty.
  static const bool mockHasNearbyDevices = true;

  /// FlutterSecureStorage keys for auth persistence.
  static const String secureAccessTokenKey = 'auth_access_token';
  static const String secureRefreshTokenKey = 'auth_refresh_token';
  static const String secureExpiresAtKey = 'auth_expires_at';
  static const String secureUserIdKey = 'auth_user_id';
  static const String secureUserEmailKey = 'auth_user_email';
  static const String secureUserNameKey = 'auth_user_name';
}
