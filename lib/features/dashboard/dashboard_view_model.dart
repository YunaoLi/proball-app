import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/stats.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/session_service.dart';
import 'package:proballdev/services/stats_notifier.dart';

/// View model for the dashboard screen.
/// Consumes data from [DeviceService] for live updates.
/// Stats from [StatsNotifier] (API-backed, persists across app restarts).
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._deviceService, this._sessionService, this._statsNotifier) {
    _deviceService.addListener(_onDeviceServiceUpdate);
    _statsNotifier.addListener(_onStatsUpdate);
    _loadPairedDevice();
  }

  final DeviceService _deviceService;
  final SessionService _sessionService;
  final StatsNotifier _statsNotifier;

  String? _pairedDeviceId;
  String? get pairedDeviceId => _pairedDeviceId;

  Future<void> _loadPairedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedDeviceId = prefs.getString(AppConstants.pairedDeviceIdKey);
    notifyListeners();
  }

  BallStatus get ballStatus => _deviceService.status;

  TodayStats? get todayStats => _statsNotifier.todayStats;
  bool get statsLoading => _statsNotifier.loading;

  PetMood get currentPetMood => _deviceService.currentPetMood;

  bool get canStartPlay =>
      _deviceService.status.isConnected &&
      !_deviceService.isRolling &&
      _deviceService.batteryState.canStartPlay &&
      _pairedDeviceId != null;

  bool get batteryDead => _deviceService.batteryState.isDead;

  /// Start session via API, then start local roll. Returns sessionId or null.
  Future<String?> startPlayAndGetSessionId() async {
    final deviceId = _pairedDeviceId;
    if (deviceId == null) return null;
    final res = await _sessionService.startSession(
      deviceId,
      batteryStart: _deviceService.status.batteryLevel,
    );
    final sessionId = res['sessionId'] as String?;
    if (sessionId != null) {
      await _deviceService.startRoll();
    }
    notifyListeners();
    return sessionId;
  }

  void _onDeviceServiceUpdate() {
    notifyListeners();
  }

  void _onStatsUpdate() {
    notifyListeners();
  }

  void refresh() {
    _statsNotifier.refresh();
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    _statsNotifier.removeListener(_onStatsUpdate);
    super.dispose();
  }
}
