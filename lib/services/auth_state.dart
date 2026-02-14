import 'package:flutter/foundation.dart';

/// Tracks auth degradation and re-auth requirements.
/// - apiDegraded: show non-blocking banner during active play when refresh fails
/// - needsReauth: navigate to login when refresh fails and NOT in active play
class AuthStateNotifier extends ChangeNotifier {
  bool _apiDegraded = false;
  bool _needsReauth = false;

  bool get apiDegraded => _apiDegraded;
  bool get needsReauth => _needsReauth;

  void setApiDegraded(bool value) {
    if (_apiDegraded != value) {
      _apiDegraded = value;
      notifyListeners();
    }
  }

  void setNeedsReauth(bool value) {
    if (_needsReauth != value) {
      _needsReauth = value;
      notifyListeners();
    }
  }

  void clearNeedsReauth() {
    setNeedsReauth(false);
  }

  void clearApiDegraded() {
    setApiDegraded(false);
  }
}
