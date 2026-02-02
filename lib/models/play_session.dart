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
  });

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

  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // seconds
  final double calories;
  final double distance; // meters
  final List<MapPoint> pathData;

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
