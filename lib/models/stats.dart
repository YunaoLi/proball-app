/// Today's aggregated stats from API (GET /api/stats/today).
class TodayStats {
  const TodayStats({
    required this.date,
    required this.totalPlayTimeSec,
    required this.totalCalories,
    required this.sessionCount,
  });

  final String date;
  final int totalPlayTimeSec;
  final double totalCalories;
  final int sessionCount;

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      date: json['date'] as String? ?? '',
      totalPlayTimeSec: (json['totalPlayTimeSec'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Daily stats point for weekly view (GET /api/stats/weekly).
class DailyStats {
  const DailyStats({
    required this.date,
    required this.totalPlayTimeSec,
    required this.totalCalories,
    required this.sessionCount,
  });

  final String date;
  final int totalPlayTimeSec;
  final double totalCalories;
  final int sessionCount;

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] as String? ?? '',
      totalPlayTimeSec: (json['totalPlayTimeSec'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
