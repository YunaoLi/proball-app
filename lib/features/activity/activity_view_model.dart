import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/play_stats.dart';
import 'package:proballdev/services/device_service.dart';

/// Data point for charts (date-based).
class ChartDataPoint {
  const ChartDataPoint({
    required this.date,
    required this.value,
    required this.label,
  });

  final DateTime date;
  final double value;
  final String label;
}

/// View model for the Activity screen.
/// Provides recent sessions, mock historical data for charts.
class ActivityViewModel extends ChangeNotifier {
  ActivityViewModel(this._deviceService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
  }

  final DeviceService _deviceService;

  BallStatus get ballStatus => _deviceService.status;

  bool get canRoll =>
      _deviceService.status.isConnected &&
      !_deviceService.isRolling &&
      _deviceService.batteryState.canStartPlay;

  bool get canStop =>
      _deviceService.status.isConnected && _deviceService.isRolling;

  /// Recent play sessions (live from DeviceService).
  List<PlayStats> get recentSessions => _deviceService.recentStats;

  /// Mock historical data: last 7 days for charts.
  /// Calories burned per day.
  List<ChartDataPoint> get caloriesHistory => _mockCaloriesHistory;

  /// Mock historical data: session duration (minutes) per day.
  List<ChartDataPoint> get durationHistory => _mockDurationHistory;

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static List<ChartDataPoint> get _mockCaloriesHistory {
    final now = DateTime.now();
    return [
      _chartPoint(now, 6, 8.2),
      _chartPoint(now, 5, 12.5),
      _chartPoint(now, 4, 6.8),
      _chartPoint(now, 3, 15.3),
      _chartPoint(now, 2, 10.1),
      _chartPoint(now, 1, 18.4),
      _chartPoint(now, 0, 14.0),
    ];
  }

  static ChartDataPoint _chartPoint(DateTime now, int daysAgo, double value) {
    final date = now.subtract(Duration(days: daysAgo));
    return ChartDataPoint(
      date: date,
      value: value,
      label: _weekdayLabels[date.weekday - 1],
    );
  }

  static List<ChartDataPoint> get _mockDurationHistory {
    final now = DateTime.now();
    return [
      _chartPoint(now, 6, 5),
      _chartPoint(now, 5, 8),
      _chartPoint(now, 4, 4),
      _chartPoint(now, 3, 10),
      _chartPoint(now, 2, 7),
      _chartPoint(now, 1, 12),
      _chartPoint(now, 0, 9),
    ];
  }

  void _onDeviceServiceUpdate() {
    notifyListeners();
  }

  Future<void> startRoll() async {
    await _deviceService.startRoll();
    notifyListeners();
  }

  Future<void> stopRoll() async {
    await _deviceService.stopRoll();
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    super.dispose();
  }
}
