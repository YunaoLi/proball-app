import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/services/api_client.dart';

/// Syncs device timezone to backend for stats aggregation ("today", weekly).
/// Fire-and-forget; no permissions required (uses OS timezone).
class TimezoneService {
  TimezoneService(this._apiClient, this._prefs);

  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  /// Get device IANA timezone (e.g. America/Chicago).
  /// Uses flutter_native_timezone which reads from OS settings.
  Future<String> getDeviceTimezoneIana() async {
    try {
      final tz = await FlutterNativeTimezone.getLocalTimezone();
      return tz.trim().isNotEmpty ? tz.trim() : 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  /// Sync timezone to backend if changed. Fire-and-forget; does not block UI.
  /// Call on app start after auto-login or after login success.
  Future<void> syncIfNeeded() async {
    try {
      final deviceTz = await getDeviceTimezoneIana();
      final lastSent = _prefs.getString(AppConstants.lastSyncedTimezoneKey);
      if (lastSent == deviceTz) return;

      final res = await _apiClient.post(
        'api/me/timezone',
        body: {'timezone': deviceTz},
        auth: true,
      );
      if (res['ok'] == true) {
        await _prefs.setString(AppConstants.lastSyncedTimezoneKey, deviceTz);
      }
    } catch (_) {
      // Fire-and-forget: retry on next app start
    }
  }
}
