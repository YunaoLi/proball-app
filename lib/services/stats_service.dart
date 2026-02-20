import 'package:proballdev/models/stats.dart';
import 'package:proballdev/services/api_client.dart';

/// Stats API: today and weekly stats from backend.
class StatsService {
  StatsService(this._api);

  final ApiClient _api;

  /// Fetch today's stats. Returns { date, totalPlayTimeSec, totalCalories, sessionCount }.
  Future<TodayStats> fetchTodayStats() async {
    final res = await _api.get('api/stats/today', auth: true);
    return TodayStats.fromJson(res);
  }

  /// Fetch weekly stats. Returns { days: [ { date, totalPlayTimeSec, totalCalories, sessionCount }, ... ] }.
  Future<List<DailyStats>> fetchWeeklyStats(int days) async {
    final res = await _api.get('api/stats/weekly?days=$days', auth: true);
    final list = res['days'] as List<dynamic>? ?? [];
    return list
        .map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
