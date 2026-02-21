import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/play_stats.dart';
import 'package:proballdev/models/stats.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/play_session_state.dart';
import 'package:proballdev/services/session_service.dart';
import 'package:proballdev/services/stats_notifier.dart';

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

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Maps ISO date (YYYY-MM-DD) to weekday label using local timezone.
/// Ensures "Sat/Sun/Mon…" matches the actual calendar date.
String _dateToWeekdayLabel(String dateStr) {
  if (dateStr.isEmpty) return '';
  try {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return _weekdayLabels[d.weekday - 1];
    }
    return dateStr.length >= 10 ? dateStr.substring(5, 10) : dateStr;
  } catch (_) {
    return dateStr.length >= 10 ? dateStr.substring(5, 10) : dateStr;
  }
}

/// View model for the Activity screen.
/// Charts use [StatsNotifier.weeklyStats] from API (oldest → newest).
class ActivityViewModel extends ChangeNotifier {
  ActivityViewModel(
    this._deviceService,
    this._sessionService,
    this._statsNotifier, {
    PlaySessionStateNotifier? playSessionState,
  })  : _playSessionState = playSessionState {
    _deviceService.addListener(_onDeviceServiceUpdate);
    _statsNotifier.addListener(_onStatsUpdate);
    _loadPairedDevice();
    _statsNotifier.refresh();
  }

  final DeviceService _deviceService;
  final SessionService _sessionService;
  final StatsNotifier _statsNotifier;
  final PlaySessionStateNotifier? _playSessionState;

  String? _pairedDeviceId;
  String? get pairedDeviceId => _pairedDeviceId;

  Future<void> _loadPairedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedDeviceId = prefs.getString(AppConstants.pairedDeviceIdKey);
    notifyListeners();
  }

  BallStatus get ballStatus => _deviceService.status;

  bool get canRoll =>
      _deviceService.status.isConnected &&
      !_deviceService.isRolling &&
      _deviceService.batteryState.canStartPlay &&
      _pairedDeviceId != null;

  bool get canStop =>
      _deviceService.status.isConnected && _deviceService.isRolling;

  /// Recent play sessions (live from DeviceService).
  List<PlayStats> get recentSessions => _deviceService.recentStats;

  /// Weekly calories from API. Oldest → newest. Labels: Thu, Fri, …
  List<ChartDataPoint> get caloriesHistory => _weeklyToCaloriesPoints(_statsNotifier.weeklyStats);

  /// Weekly duration (minutes) from API. Oldest → newest.
  List<ChartDataPoint> get durationHistory => _weeklyToDurationPoints(_statsNotifier.weeklyStats);

  bool get chartsLoading => _statsNotifier.loading;

  static List<ChartDataPoint> _weeklyToCaloriesPoints(List<DailyStats> days) {
    return days.map((ds) => ChartDataPoint(
      date: _parseDate(ds.date),
      value: ds.totalCalories.toDouble(),
      label: _dateToWeekdayLabel(ds.date),
    )).toList();
  }

  static List<ChartDataPoint> _weeklyToDurationPoints(List<DailyStats> days) {
    return days.map((ds) => ChartDataPoint(
      date: _parseDate(ds.date),
      value: ds.totalPlayTimeSec / 60.0,
      label: _dateToWeekdayLabel(ds.date),
    )).toList();
  }

  /// Parse ISO date as local calendar date (for correct weekday).
  static DateTime _parseDate(String s) {
    try {
      final parts = s.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime.tryParse(s) ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  void _onDeviceServiceUpdate() {
    notifyListeners();
  }

  void _onStatsUpdate() {
    notifyListeners();
  }

  Future<void> startRoll() async {
    await _deviceService.startRoll();
    notifyListeners();
  }

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
      _playSessionState?.setActive(
        sessionId: sessionId,
        startedAt: DateTime.now(),
        deviceId: deviceId,
      );
    }
    notifyListeners();
    return sessionId;
  }

  Future<void> stopRoll() async {
    await _deviceService.stopRoll();
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    _statsNotifier.removeListener(_onStatsUpdate);
    super.dispose();
  }
}
