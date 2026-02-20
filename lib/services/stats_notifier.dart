import 'package:flutter/foundation.dart';
import 'package:proballdev/models/stats.dart';
import 'package:proballdev/services/stats_service.dart';

/// Holds today and weekly stats from API. Call [refresh] after session end or on Dashboard mount.
class StatsNotifier extends ChangeNotifier {
  StatsNotifier(this._statsService, {int defaultWeeklyDays = 7}) : _weeklyDays = defaultWeeklyDays;

  final StatsService _statsService;
  int _weeklyDays;

  TodayStats? _todayStats;
  TodayStats? get todayStats => _todayStats;

  List<DailyStats> _weeklyStats = [];
  List<DailyStats> get weeklyStats => List.unmodifiable(_weeklyStats);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// Refresh both today and weekly stats. Call after session end or when Dashboard appears.
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _statsService.fetchTodayStats(),
        _statsService.fetchWeeklyStats(_weeklyDays),
      ]);
      _todayStats = results[0] as TodayStats;
      _weeklyStats = results[1] as List<DailyStats>;
    } catch (e) {
      _error = e.toString();
      _todayStats ??= TodayStats(date: '', totalPlayTimeSec: 0, totalCalories: 0, sessionCount: 0);
      _weeklyStats = [];
    }
    _loading = false;
    notifyListeners();
  }

  /// Refresh only today stats (lighter call).
  Future<void> refreshToday() async {
    try {
      _todayStats = await _statsService.fetchTodayStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set number of days for weekly stats. Call [refresh] to apply.
  void setWeeklyDays(int days) {
    if (_weeklyDays != days) {
      _weeklyDays = days;
    }
  }
}
