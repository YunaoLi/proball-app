import 'dart:math';

import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/models/play_stats.dart';

/// Completed play session record.
/// Canonical model for a single play session; used for historical sessions,
/// AI reports, and aggregating today's totals.
class PlaySession {
  const PlaySession({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.calories,
    required this.distance,
    required this.pathData,
    this.deviceId,
    this.status,
    this.metrics,
  });

  /// Parse from backend API response.
  factory PlaySession.fromJson(Map<String, dynamic> json) {
    final startedAt = json['startedAt'] as String?;
    final endedAt = json['endedAt'] as String?;
    final startTime = startedAt != null
        ? DateTime.tryParse(startedAt) ?? DateTime.now()
        : DateTime.now();
    final endTime = endedAt != null
        ? DateTime.tryParse(endedAt) ?? startTime
        : startTime;
    final duration = (json['durationSec'] as num?)?.toInt() ??
        endTime.difference(startTime).inSeconds;
    final calories = (json['calories'] as num?)?.toDouble() ?? 0.0;
    return PlaySession(
      sessionId: json['sessionId'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      status: json['status'] as String?,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      calories: calories,
      distance: 0,
      pathData: const [],
      metrics: json['metrics'] as Map<String, dynamic>?,
    );
  }

  factory PlaySession.fromPathData({
    required String sessionId,
    required DateTime startTime,
    required DateTime endTime,
    required double calories,
    required List<MapPoint> pathData,
  }) {
    final duration = endTime.difference(startTime).inSeconds;
    final distance = _computePathDistance(pathData);
    return PlaySession(
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      calories: calories,
      distance: distance,
      pathData: pathData,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        if (deviceId != null) 'deviceId': deviceId,
        if (status != null) 'status': status,
        'startedAt': startTime.toIso8601String(),
        'endedAt': endTime.toIso8601String(),
        'durationSec': duration,
        'calories': calories,
        if (metrics != null) 'metrics': metrics,
      };

  final String sessionId;
  final String? deviceId;
  final String? status;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // seconds
  final double calories;
  final double distance; // meters
  final List<MapPoint> pathData;
  final Map<String, dynamic>? metrics;

  static double _computePathDistance(List<MapPoint> pts) {
    if (pts.length < 2) return 0;
    var d = 0.0;
    for (var i = 1; i < pts.length; i++) {
      d += sqrt(
        pow(pts[i].x - pts[i - 1].x, 2) + pow(pts[i].y - pts[i - 1].y, 2),
      );
    }
    return d;
  }

  /// Converts to [PlayStats] for backward compatibility with Dashboard/Activity.
  PlayStats toPlayStats() => PlayStats(
        elapsedTime: duration,
        caloriesBurned: calories,
        distance: distance,
        date: endTime,
      );
}
