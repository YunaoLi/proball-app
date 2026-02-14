import 'package:flutter/foundation.dart';

/// Global play session state for auth-degraded handling.
/// When auth fails during ACTIVE play, we do NOT navigate away.
enum PlaySessionPhase {
  idle,
  active,
  ending,
}

class PlaySessionState {
  const PlaySessionState({
    required this.phase,
    this.sessionId,
    this.startedAt,
    this.deviceId,
  });

  final PlaySessionPhase phase;
  final String? sessionId;
  final DateTime? startedAt;
  final String? deviceId;

  bool get isActive => phase == PlaySessionPhase.active;
  bool get isIdle => phase == PlaySessionPhase.idle;
  bool get isEnding => phase == PlaySessionPhase.ending;

  PlaySessionState copyWith({
    PlaySessionPhase? phase,
    String? sessionId,
    DateTime? startedAt,
    String? deviceId,
  }) {
    return PlaySessionState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  static const idle = PlaySessionState(phase: PlaySessionPhase.idle);
}

/// Global provider for play session state. Used by ApiClient to decide
/// whether to redirect to login on auth failure (no redirect if active).
class PlaySessionStateNotifier extends ChangeNotifier {
  PlaySessionState _state = PlaySessionState.idle;
  PlaySessionState get state => _state;

  void setActive({required String sessionId, required DateTime startedAt, required String deviceId}) {
    _state = PlaySessionState(
      phase: PlaySessionPhase.active,
      sessionId: sessionId,
      startedAt: startedAt,
      deviceId: deviceId,
    );
    notifyListeners();
  }

  void setEnding() {
    _state = _state.copyWith(phase: PlaySessionPhase.ending);
    notifyListeners();
  }

  void setIdle() {
    _state = PlaySessionState.idle;
    notifyListeners();
  }
}
