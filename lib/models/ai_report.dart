import 'package:proballdev/models/pet_mood.dart';

/// AI-generated report summarizing a play session.
/// One report per [PlaySession], linked via [sessionId].
/// Designed for future ML/AI API integration.
class AiReport {
  const AiReport({
    required this.sessionId,
    required this.summaryText,
    required this.mood,
    required this.confidence,
    required this.timestamp,
    this.caloriesBurned,
    this.elapsedSeconds,
    this.distance,
    this.insight,
  });

  /// Links this report to its [PlaySession].
  final String sessionId;
  final String summaryText;
  final PetMood mood;
  final double confidence; // 0.0 - 1.0
  final DateTime timestamp;
  final double? caloriesBurned;
  final int? elapsedSeconds;
  final double? distance;
  /// AI-generated natural language insight (key takeaway).
  final String? insight;

  String get formattedDuration {
    if (elapsedSeconds == null) return '—';
    final m = elapsedSeconds! ~/ 60;
    final s = elapsedSeconds! % 60;
    return '${m}m ${s}s';
  }
}
