import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/services/auth_service.dart';

/// Single source of truth for app-level gating.
/// Used to decide when to show ball status, battery errors, etc.
class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier(this._authService);

  final AuthService _authService;

  bool _hasPairedDevice = false;

  /// User has valid auth token.
  bool get isLoggedIn => _authService.hasToken;

  /// User has a paired device (from local cache).
  bool get hasPairedDevice => _hasPairedDevice;

  /// Ball status should be shown: logged in + paired + (optionally) connected.
  /// Battery errors should only be shown when this is true.
  bool get shouldShowBallStatus => isLoggedIn && _hasPairedDevice;

  /// Refresh state from storage. Call on init, after login, after pair, after logout.
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final paired = prefs.getString(AppConstants.pairedDeviceIdKey);
    final hadPaired = _hasPairedDevice;
    _hasPairedDevice = paired != null && paired.isNotEmpty;
    if (hadPaired != _hasPairedDevice) {
      notifyListeners();
    }
  }
}
