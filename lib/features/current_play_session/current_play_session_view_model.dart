import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/features/map/map_view_model.dart';

/// View model for the Current Play Session screen.
/// Shows live session data: timer, calories, distance, path.
/// UI-agnostic: works with MockDeviceService or BleDeviceService.
class CurrentPlaySessionViewModel extends ChangeNotifier {
  CurrentPlaySessionViewModel(this._deviceService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
    _deviceService.positionStream.listen(_onPositionsUpdate);
    if (_deviceService.isRolling) _startTimer();
  }

  final DeviceService _deviceService;

  Timer? _timer;
  final ValueNotifier<int> _elapsedNotifier = ValueNotifier<int>(0);

  /// Live elapsed seconds. Updates every second.
  ValueListenable<int> get elapsedListenable => _elapsedNotifier;

  int get elapsedSeconds => _elapsedNotifier.value;

  /// Live calories (mock formula: ~0.03 cal/s + distance factor).
  double get liveCalories =>
      _computeLiveCalories(_elapsedNotifier.value, _deviceService.currentSessionDistance);

  /// Live distance (meters) from device.
  double get liveDistance => _deviceService.currentSessionDistance;

  /// Battery level (0–100) from device.
  int get batteryLevel => _deviceService.status.batteryLevel;

  /// Current path for map visualization.
  List<MapPoint> get pathPositions => _deviceService.lastPositions;

  /// Indoor map zones (static layout).
  static List<MapZone> get roomZones => MapViewModel.roomZones;

  /// Activity zones for path heat overlay. Empty for minimal live map.
  List<ActivityZone> get activityZones => _computeActivityZones(pathPositions);

  bool get isRolling => _deviceService.isRolling;

  void _startTimer() {
    _timer?.cancel();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    final start = _deviceService.currentSessionStartTime;
    if (start == null) return;
    _elapsedNotifier.value = DateTime.now().difference(start).inSeconds;
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  double _computeLiveCalories(int elapsedSeconds, double distanceMeters) {
    const baseCalPerSec = 0.03;
    const distanceCalPerMeter = 0.15;
    return (elapsedSeconds * baseCalPerSec + distanceMeters * distanceCalPerMeter)
        .clamp(0.0, 999.9);
  }

  List<ActivityZone> _computeActivityZones(List<MapPoint> positions) {
    if (positions.length < 2) return [];
    const gridSize = 4;
    const roomW = 5.0;
    const roomH = 4.0;
    final cellW = roomW / gridSize;
    final cellH = roomH / gridSize;
    final counts = List.filled(gridSize * gridSize, 0);

    for (final p in positions) {
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

  void _onDeviceServiceUpdate() {
    if (!_deviceService.isRolling) {
      _stopTimer();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void _onPositionsUpdate(List<MapPoint> _) {
    notifyListeners();
  }

  Future<void> stopPlay() async {
    _stopTimer();
    await _deviceService.stopRoll();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    _elapsedNotifier.dispose();
    _deviceService.removeListener(_onDeviceServiceUpdate);
    super.dispose();
  }
}
