import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/services/device_service.dart';

/// Zone in the abstract indoor map with name and bounds.
class MapZone {
  const MapZone({
    required this.name,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final String name;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  bool contains(double x, double y) =>
      x >= xMin && x <= xMax && y >= yMin && y <= yMax;
}

/// High-activity zone for heat overlay.
class ActivityZone {
  const ActivityZone({
    required this.x,
    required this.y,
    required this.count,
    required this.intensity,
  });

  final double x;
  final double y;
  final double count;
  final double intensity; // 0.0 - 1.0
}

/// View model for the Map Analysis screen.
/// Provides path, zones, distance, AI insights.
/// UI-agnostic: works with MockDeviceService or BleDeviceService.
class MapViewModel extends ChangeNotifier {
  MapViewModel(this._deviceService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
    _deviceService.positionStream.listen(_onPositionsUpdate);
    _positions = _deviceService.lastPositions.isNotEmpty
        ? _deviceService.lastPositions
        : _mockPathForDemo;
  }

  final DeviceService _deviceService;

  List<MapPoint> _positions = [];
  static final _mockPathForDemo = _generateMockPath();

  static List<MapPoint> _generateMockPath() {
    final base = DateTime.now();
    final r = Random(42);
    final points = <MapPoint>[];
    double x = 0.8;
    double y = 0.8;
    for (var i = 0; i < 20; i++) {
      points.add(MapPoint(x: x, y: y, timestamp: base.add(Duration(seconds: i))));
      x += (r.nextDouble() - 0.4) * 1.2;
      y += (r.nextDouble() - 0.4) * 1.0;
      x = x.clamp(0.3, 4.7);
      y = y.clamp(0.3, 3.7);
    }
    return points;
  }

  List<MapPoint> get positions => List.unmodifiable(_positions);

  /// Total distance traveled (meters, abstract units).
  double get totalDistance => _computePathDistance(_positions);

  /// High-activity zones for heat overlay.
  List<ActivityZone> get activityZones => _computeActivityZones();

  /// Mock AI insights for overlay.
  List<String> get aiInsights => _computeAiInsights();

  /// Indoor map zones (abstract room layout).
  static const roomZones = [
    MapZone(name: 'Sofa', xMin: 0, xMax: 2, yMin: 0, yMax: 1.5),
    MapZone(name: 'Window', xMin: 2, xMax: 3.5, yMin: 0, yMax: 0.8),
    MapZone(name: 'Table', xMin: 3, xMax: 5, yMin: 1, yMax: 2.5),
    MapZone(name: 'Center', xMin: 1.5, xMax: 3.5, yMin: 1.5, yMax: 2.5),
    MapZone(name: 'Door', xMin: 0, xMax: 1, yMin: 2.5, yMax: 4),
    MapZone(name: 'Corner', xMin: 3.5, xMax: 5, yMin: 2.5, yMax: 4),
  ];

  void _onDeviceServiceUpdate() {
    notifyListeners();
  }

  void _onPositionsUpdate(List<MapPoint> pts) {
    _positions = pts;
    notifyListeners();
  }

  double _computePathDistance(List<MapPoint> pts) {
    if (pts.length < 2) return 0;
    var d = 0.0;
    for (var i = 1; i < pts.length; i++) {
      d += sqrt(
        pow(pts[i].x - pts[i - 1].x, 2) + pow(pts[i].y - pts[i - 1].y, 2),
      );
    }
    return d;
  }

  List<ActivityZone> _computeActivityZones() {
    if (_positions.isEmpty) return [];
    const gridSize = 4;
    const roomW = 5.0;
    const roomH = 4.0;
    final cellW = roomW / gridSize;
    final cellH = roomH / gridSize;
    final counts = List.filled(gridSize * gridSize, 0);

    for (final p in _positions) {
      final col = ((p.x / roomW) * gridSize).floor().clamp(0, gridSize - 1);
      final row = ((p.y / roomH) * gridSize).floor().clamp(0, gridSize - 1);
      counts[row * gridSize + col]++;
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return [];

    final zones = <ActivityZone>[];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final i = r * gridSize + c;
        if (counts[i] > 0) {
          zones.add(ActivityZone(
            x: (c + 0.5) * cellW,
            y: (r + 0.5) * cellH,
            count: counts[i].toDouble(),
            intensity: (counts[i] / maxCount).clamp(0.2, 1.0),
          ));
        }
      }
    }
    return zones;
  }

  List<String> _computeAiInsights() {
    final insights = <String>[];
    if (_positions.isEmpty) {
      insights.add('Start a play session to see path analysis.');
      return insights;
    }
    insights.add('Total distance: ${totalDistance.toStringAsFixed(1)}m');
    final hotZone = _findHottestZone();
    if (hotZone != null) {
      insights.add('Most activity detected near the $hotZone area.');
    }
    insights.add('Path shows ${_positions.length} recorded points.');
    return insights;
  }

  String? _findHottestZone() {
    if (_positions.isEmpty) return null;
    final zoneCounts = <String, int>{};
    for (final z in roomZones) {
      zoneCounts[z.name] = 0;
    }
    for (final p in _positions) {
      for (final z in roomZones) {
        if (z.contains(p.x, p.y)) {
          zoneCounts[z.name] = (zoneCounts[z.name] ?? 0) + 1;
          break;
        }
      }
    }
    var maxCount = 0;
    String? hottest;
    zoneCounts.forEach((name, count) {
      if (count > maxCount) {
        maxCount = count;
        hottest = name.toLowerCase();
      }
    });
    return hottest;
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    super.dispose();
  }
}
