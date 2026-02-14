import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';

/// Persists JWT token and minimal user info in SharedPreferences.
class TokenStore extends ChangeNotifier {
  TokenStore(this._prefs);

  final SharedPreferences _prefs;

  String? _token;
  String? _userId;
  String? _userEmail;
  String? _userName;

  String? get token => _token ?? _prefs.getString(AppConstants.tokenStorageKey);
  String? get userId => _userId ?? _prefs.getString(AppConstants.userIdStorageKey);
  String? get userEmail => _userEmail ?? _prefs.getString(AppConstants.userEmailStorageKey);
  String? get userName => _userName ?? _prefs.getString(AppConstants.userNameStorageKey);

  bool get hasToken {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  Future<void> save({
    required String accessToken,
    String? userId,
    String? email,
    String? name,
  }) async {
    await _prefs.setString(AppConstants.tokenStorageKey, accessToken);
    if (userId != null) await _prefs.setString(AppConstants.userIdStorageKey, userId);
    if (email != null) await _prefs.setString(AppConstants.userEmailStorageKey, email);
    if (name != null) await _prefs.setString(AppConstants.userNameStorageKey, name);
    _token = accessToken;
    _userId = userId;
    _userEmail = email;
    _userName = name;
    notifyListeners();
  }

  Future<void> clear() async {
    await _prefs.remove(AppConstants.tokenStorageKey);
    await _prefs.remove(AppConstants.userIdStorageKey);
    await _prefs.remove(AppConstants.userEmailStorageKey);
    await _prefs.remove(AppConstants.userNameStorageKey);
    _token = null;
    _userId = null;
    _userEmail = null;
    _userName = null;
    notifyListeners();
  }
}
