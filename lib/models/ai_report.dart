import 'package:proballdev/models/pet_mood.dart';

/// AI-generated report summarizing a play session.
/// One report per [PlaySession], linked via [sessionId].
/// Supports both mock format and backend API format.
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
    this.status,
    this.contentJson,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from backend GET /api/reports/{sessionId} response.
  factory AiReport.fromBackendJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'PENDING';
    final content = json['content'] as Map<String, dynamic>?;
    String summaryText = '';
    double? caloriesBurned;
    int? elapsedSeconds;
    String? insight;
    DateTime timestamp = DateTime.now();

    if (content != null) {
      summaryText = content['summary'] as String? ?? content['summaryTitle'] as String? ?? '';
      final stats = content['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        caloriesBurned = (stats['calories'] as num?)?.toDouble();
        elapsedSeconds = (stats['durationSec'] as num?)?.toInt();
      }
      final highlights = content['highlights'] as List<dynamic>?;
      insight = highlights?.isNotEmpty == true ? highlights!.first.toString() : null;
      final genAt = content['generatedAt'] as String?;
      if (genAt != null) timestamp = DateTime.tryParse(genAt) ?? timestamp;
    }

    return AiReport(
      sessionId: json['sessionId'] as String? ?? '',
      status: status,
      summaryText: summaryText,
      mood: PetMood.happy,
      confidence: 0.85,
      timestamp: timestamp,
      caloriesBurned: caloriesBurned,
      elapsedSeconds: elapsedSeconds,
      insight: insight,
      contentJson: content,
      failureReason: json['failureReason'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  /// Parse from list item (GET /api/reports).
  factory AiReport.fromListJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] as String?;
    return AiReport(
      sessionId: json['sessionId'] as String? ?? '',
      status: json['status'] as String?,
      summaryText: '',
      mood: PetMood.happy,
      confidence: 0,
      timestamp: updatedAt != null ? DateTime.tryParse(updatedAt) ?? DateTime.now() : DateTime.now(),
      caloriesBurned: (json['calories'] as num?)?.toDouble(),
      elapsedSeconds: (json['durationSec'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'status': status,
        'content': contentJson,
        'failureReason': failureReason,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

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
  /// Backend status: PENDING, READY, FAILED.
  final String? status;
  /// Raw content from backend when READY.
  final Map<String, dynamic>? contentJson;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get formattedDuration {
    if (elapsedSeconds == null) return '—';
    final m = elapsedSeconds! ~/ 60;
    final s = elapsedSeconds! % 60;
    return '${m}m ${s}s';
  }
}
