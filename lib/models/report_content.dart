/// Parsed AI report content from backend. Strongly typed for ReportCard display.
class ReportContent {
  const ReportContent({
    required this.summaryTitle,
    required this.summary,
    required this.highlights,
    required this.stats,
    required this.recommendations,
    required this.generatedAt,
  });

  final String summaryTitle;
  final String summary;
  final List<String> highlights;
  final ReportStats stats;
  final List<String> recommendations;
  final DateTime generatedAt;

  /// Parse from backend contentJson (when status is READY).
  factory ReportContent.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>?;
    final stats = statsJson != null
        ? ReportStats(
            durationSec: (statsJson['durationSec'] as num?)?.toInt() ?? 0,
            calories: (statsJson['calories'] as num?)?.toDouble(),
            batteryDelta: (statsJson['batteryDelta'] as num?)?.toInt(),
          )
        : const ReportStats(durationSec: 0, calories: null, batteryDelta: null);

    final highlightsRaw = json['highlights'] as List<dynamic>?;
    final highlights = highlightsRaw != null
        ? highlightsRaw
            .whereType<String>()
            .map((e) => e as String)
            .toList()
        : <String>[];

    final recsRaw = json['recommendations'] as List<dynamic>?;
    final recommendations = recsRaw != null
        ? recsRaw
            .whereType<String>()
            .map((e) => e as String)
            .toList()
        : <String>[];

    final genAt = json['generatedAt'] as String?;
    final generatedAt = genAt != null
        ? DateTime.tryParse(genAt) ?? DateTime.now()
        : DateTime.now();

    return ReportContent(
      summaryTitle: json['summaryTitle'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      highlights: highlights,
      stats: stats,
      recommendations: recommendations,
      generatedAt: generatedAt,
    );
  }
}

class ReportStats {
  const ReportStats({
    required this.durationSec,
    this.calories,
    this.batteryDelta,
  });

  final int durationSec;
  final double? calories;
  final int? batteryDelta;
}
