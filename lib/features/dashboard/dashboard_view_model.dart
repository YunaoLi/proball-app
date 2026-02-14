import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/play_stats.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/session_service.dart';

/// View model for the dashboard screen.
/// Consumes data from [DeviceService] for live updates.
/// Integrates with backend: startSession, then startRoll.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._deviceService, this._sessionService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
    _loadPairedDevice();
  }

  final DeviceService _deviceService;
  final SessionService _sessionService;

  String? _pairedDeviceId;
  String? get pairedDeviceId => _pairedDeviceId;

  Future<void> _loadPairedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedDeviceId = prefs.getString(AppConstants.pairedDeviceIdKey);
    notifyListeners();
  }

  BallStatus get ballStatus => _deviceService.status;

  List<PlayStats> get recentStats => _deviceService.recentStats;

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

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    super.dispose();
  }
}
