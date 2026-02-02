import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:proballdev/models/app_error.dart';

/// Centralized error handling. Emits errors to UI layers.
/// Prevents duplicate spam: one emission per state change.
class ErrorManager extends ChangeNotifier {
  ErrorManager() {
    _controller = StreamController<AppError>.broadcast();
  }

  late final StreamController<AppError> _controller;

  /// Subscribe for error display (snackbar, banner, dialog).
  Stream<AppError> get errorStream => _controller.stream;

  /// Last emitted error for immediate UI reads.
  AppError? _lastError;
  AppError? get lastError => _lastError;

  /// Last battery state we warned about (avoids spam).
  BatteryWarningState? _lastBatteryWarning;

  void _emit(AppError error, {BatteryWarningState? batteryState}) {
    if (batteryState != null) {
      if (_lastBatteryWarning == batteryState) return;
      _lastBatteryWarning = batteryState;
    }
    _lastError = error;
    _controller.add(error);
    notifyListeners();
  }

  /// Emit battery dead (blocking). Always shown.
  void emitBatteryDead() {
    _lastBatteryWarning = BatteryWarningState.dead;
    final error = const AppError(
      type: AppErrorType.battery,
      severity: AppErrorSeverity.critical,
      userMessage: 'Battery depleted. Please charge the ball to continue.',
      debugMessage: 'Battery 0%',
    );
    _lastError = error;
    _controller.add(error);
    notifyListeners();
  }

  /// Emit battery low (non-blocking). Once per transition.
  void emitBatteryLow() {
    _emit(
      const AppError(
        type: AppErrorType.battery,
        severity: AppErrorSeverity.warning,
        userMessage: 'Battery low — please charge soon',
        debugMessage: 'Battery 10–19%',
      ),
      batteryState: BatteryWarningState.low,
    );
  }

  /// Emit battery critical (non-blocking). Once per transition.
  void emitBatteryCritical() {
    _emit(
      const AppError(
        type: AppErrorType.battery,
        severity: AppErrorSeverity.warning,
        userMessage: 'Battery critical — charge soon',
        debugMessage: 'Battery 1–9%',
      ),
      batteryState: BatteryWarningState.critical,
    );
  }

  /// Emit generic error.
  void emit(AppError error) {
    _lastError = error;
    _controller.add(error);
    notifyListeners();
  }

  /// Clear last error (e.g. after user dismisses).
  void clearLast() {
    _lastError = null;
    notifyListeners();
  }

  /// Reset battery warning state (e.g. when battery recovers).
  void resetBatteryWarning() {
    _lastBatteryWarning = null;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

enum BatteryWarningState {
  low,
  critical,
  dead,
}
