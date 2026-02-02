import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/play_stats.dart';
import 'package:proballdev/services/device_service.dart';

/// View model for the dashboard screen.
/// Consumes data from [DeviceService] for live updates.
/// UI-agnostic: works with MockDeviceService or BleDeviceService.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._deviceService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
  }

  final DeviceService _deviceService;

  BallStatus get ballStatus => _deviceService.status;

  List<PlayStats> get recentStats => _deviceService.recentStats;

  PetMood get currentPetMood => _deviceService.currentPetMood;

  bool get canStartPlay =>
      _deviceService.status.isConnected &&
      !_deviceService.isRolling &&
      _deviceService.batteryState.canStartPlay;

  bool get batteryDead => _deviceService.batteryState.isDead;

  Future<void> startPlay() async {
    await _deviceService.startRoll();
    notifyListeners();
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
