import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/battery_state.dart';
import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/play_session.dart';
import 'package:proballdev/models/play_stats.dart';
import 'package:proballdev/services/api_client.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/error_manager.dart';

/// Mock implementation of [DeviceService] for UI-first development.
/// Simulates: connection, battery drain, play sessions, calories,
/// pet mood, AI report per session (generated on session complete).
/// Swap for [BleDeviceService] in app.dart when BLE hardware is ready.
class MockDeviceService extends DeviceService {
  MockDeviceService({
    required ErrorManager errorManager,
    ApiClient? apiClient,
  })  : _errorManager = errorManager,
        _apiClient = apiClient {
    _statusController = StreamController<BallStatus>.broadcast();
    _positionController = StreamController<List<MapPoint>>.broadcast();
    _playStatsController = StreamController<List<PlayStats>>.broadcast();
    _petMoodController = StreamController<PetMood>.broadcast();
    _aiReportController = StreamController<List<AiReport>>.broadcast();

    _startBatteryDrainTimer();
  }

  final ErrorManager _errorManager;
  final ApiClient? _apiClient;

  static const int _initialBattery = 85;
  static const Duration _batteryDrainInterval = Duration(seconds: 30);

  BallStatus _status = const BallStatus(
    batteryLevel: _initialBattery,
    mode: BallMode.normal,
    isConnected: true,
  );
  bool _isRolling = false;
  List<MapPoint> _positions = [];
  DateTime? _sessionStartTime;
  double _sessionDistance = 0;
  final List<PlaySession> _recentSessions = [];
  final List<AiReport> _reports = [];
  PetMood _currentPetMood = PetMood.happy;
  Timer? _batteryTimer;
  final Random _random = Random();

  late final StreamController<BallStatus> _statusController;
  late final StreamController<List<MapPoint>> _positionController;
  late final StreamController<List<PlayStats>> _playStatsController;
  late final StreamController<PetMood> _petMoodController;
  late final StreamController<List<AiReport>> _aiReportController;

  @override
  BallStatus get status => _status;

  @override
  bool get isRolling => _isRolling;

  @override
  Stream<BallStatus> get statusStream => _statusController.stream;

  @override
  Stream<List<MapPoint>> get positionStream => _positionController.stream;

  @override
  List<MapPoint> get lastPositions => List.unmodifiable(_positions);

  @override
  DateTime? get currentSessionStartTime => _isRolling ? _sessionStartTime : null;

  @override
  double get currentSessionDistance => _sessionDistance;

  @override
  List<PlaySession> get recentSessions => List.unmodifiable(_recentSessions);

  @override
  List<PlayStats> get recentStats =>
      _recentSessions.map((s) => s.toPlayStats()).toList();

  Stream<List<PlayStats>> get playStatsStream => _playStatsController.stream;

  @override
  PetMood get currentPetMood => _currentPetMood;

  Stream<PetMood> get petMoodStream => _petMoodController.stream;

  @override
  List<AiReport> get reports => List.unmodifiable(_reports);

  Stream<List<AiReport>> get reportsStream => _aiReportController.stream;

  @override
  Future<Map<String, dynamic>> pairDevice({
    required String deviceId,
    String? deviceName,
  }) async {
    if (_apiClient == null) {
      throw UnimplementedError('ApiClient required for pairDevice');
    }
    return _apiClient!.post(
      'api/devices/pair',
      body: {
        'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
      },
      auth: true,
    );
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    if (_apiClient == null) {
      throw UnimplementedError('ApiClient required for getMe');
    }
    return _apiClient!.get('api/me', auth: true);
  }

  @override
  Future<bool> connect() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _status = BallStatus(
      batteryLevel: _status.batteryLevel > 0 ? _status.batteryLevel : _initialBattery,
      mode: BallMode.normal,
      isConnected: true,
    );
    _statusController.add(_status);
    notifyListeners();
    return true;
  }

  @override
  Future<void> disconnect() async {
    _status = BallStatus.disconnected;
    _statusController.add(_status);
    notifyListeners();
  }

  @override
  Future<void> startRoll() async {
    if (!_status.isConnected) return;

    final batteryState = BatteryState.fromPercentage(_status.batteryLevel);
    if (batteryState.isDead) {
      _errorManager.emitBatteryDead();
      return;
    }

    _isRolling = true;
    _sessionStartTime = DateTime.now();
    _sessionDistance = 0;
    _simulateIndoorPath();
    notifyListeners();
  }

  @override
  Future<void> stopRoll() async {
    if (!_isRolling) return;

    _isRolling = false;

    try {
      // Complete session and persist as PlaySession
      if (_sessionStartTime != null) {
        final endTime = DateTime.now();
        final elapsed = endTime.difference(_sessionStartTime!).inSeconds;
        final calories = _computeCalories(elapsed, _sessionDistance);
        final sessionId =
            '${_sessionStartTime!.millisecondsSinceEpoch}-${_random.nextInt(10000)}';

        final session = PlaySession.fromPathData(
          sessionId: sessionId,
          startTime: _sessionStartTime!,
          endTime: endTime,
          calories: calories,
          pathData: List.from(_positions),
        );
        _recentSessions.insert(0, session);
        if (_recentSessions.length > 10) _recentSessions.removeLast();
        _playStatsController.add(recentStats);

        // Generate exactly one AI report per session (deterministic mock).
        final report = _generateAiReportForSession(session);
        _reports.insert(0, report);
        if (_reports.length > 50) _reports.removeLast();
        _aiReportController.add(reports);
      }

      _currentPetMood = _randomPetMood();
      _petMoodController.add(_currentPetMood);
    } catch (e, st) {
      debugPrint('MockDeviceService: stopRoll error: $e\n$st');
      rethrow;
    }

    notifyListeners();
  }

  /// Deterministic mock AI generation: same sessionId always yields same report.
  AiReport _generateAiReportForSession(PlaySession session) {
    final seed = session.sessionId.hashCode;
    final r = Random(seed);

    const summaries = [
      'Your pet showed excellent engagement. Ball movement patterns '
          'triggered high chase interest, and energy levels remained elevated.',
      'Good session! Energy levels remained elevated throughout. '
          'Movement variety kept your pet engaged.',
      'Calm play. Your pet enjoyed moderate activity—'
          'perfect for a relaxed session.',
      'High-energy session! Frequent direction changes suggest '
          'strong play drive and engagement.',
      'Steady engagement throughout. Your pet maintained interest '
          'without overexertion.',
    ];
    const insights = [
      'Most activity concentrated near furniture—great chase response.',
      'Sustained engagement suggests ideal play duration for your pet.',
      'Movement patterns indicate strong interest in interactive play.',
      'Distance covered shows healthy activity level for this session.',
      'Path variety kept your pet curious and engaged.',
    ];
    final moodIndex = r.nextInt(PetMood.values.length);
    final mood = PetMood.values[moodIndex];
    final confidence = 0.72 + r.nextDouble() * 0.22;

    return AiReport(
      sessionId: session.sessionId,
      summaryText: summaries[r.nextInt(summaries.length)],
      mood: mood,
      confidence: confidence,
      timestamp: session.endTime,
      caloriesBurned: session.calories,
      elapsedSeconds: session.duration,
      distance: session.distance,
      insight: insights[r.nextInt(insights.length)],
    );
  }

  void _startBatteryDrainTimer() {
    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(_batteryDrainInterval, (_) {
      if (!_status.isConnected) return;

      final drain = _isRolling ? 2 : 1;
      final newLevel = (_status.batteryLevel - drain).clamp(0, 100);
      final prevState = BatteryState.fromPercentage(_status.batteryLevel);
      final newState = BatteryState.fromPercentage(newLevel);

      _status = _status.copyWith(batteryLevel: newLevel);
      _statusController.add(_status);

      if (newState.isDead) {
        _errorManager.emitBatteryDead();
        if (_isRolling) _safeStopSession();
      } else if (newState.isCritical && !prevState.isCritical) {
        _errorManager.emitBatteryCritical();
      } else if (newState.isLow && !prevState.isLow && !prevState.isCritical) {
        _errorManager.emitBatteryLow();
      } else if (newState.isNormal) {
        _errorManager.resetBatteryWarning();
      }

      notifyListeners();
    });
  }

  void _safeStopSession() {
    if (!_isRolling) return;
    _isRolling = false;

    try {
      if (_sessionStartTime != null) {
        final endTime = DateTime.now();
        final elapsed = endTime.difference(_sessionStartTime!).inSeconds;
        final calories = _computeCalories(elapsed, _sessionDistance);
        final sessionId =
            '${_sessionStartTime!.millisecondsSinceEpoch}-${_random.nextInt(10000)}';

        final session = PlaySession.fromPathData(
          sessionId: sessionId,
          startTime: _sessionStartTime!,
          endTime: endTime,
          calories: calories,
          pathData: List.from(_positions),
        );
        _recentSessions.insert(0, session);
        if (_recentSessions.length > 10) _recentSessions.removeLast();
        _playStatsController.add(recentStats);

        final report = _generateAiReportForSession(session);
        _reports.insert(0, report);
        if (_reports.length > 50) _reports.removeLast();
        _aiReportController.add(reports);
      }
      _currentPetMood = _randomPetMood();
      _petMoodController.add(_currentPetMood);
    } catch (e, st) {
      debugPrint('MockDeviceService: safe session teardown error: $e\n$st');
    }
  }

  PetMood _randomPetMood() {
    final moods = PetMood.values;
    return moods[_random.nextInt(moods.length)];
  }

  double _computeCalories(int elapsedSeconds, double distanceMeters) {
    // Rough formula: ~0.03 cal/sec base + distance factor
    final baseCal = elapsedSeconds * 0.03;
    final distanceCal = distanceMeters * 0.15;
    return (baseCal + distanceCal + _random.nextDouble() * 2).clamp(1.0, 50.0);
  }

  void _simulateIndoorPath() {
    // Indoor room-like path: rectangle ~5x4 units with turns
    final base = DateTime.now();
    final roomWidth = 5.0;
    final roomHeight = 4.0;
    final pointCount = 15 + _random.nextInt(10);
    final points = <MapPoint>[];
    double x = 0.5;
    double y = 0.5;

    for (var i = 0; i < pointCount; i++) {
      final t = base.add(Duration(seconds: i));
      points.add(MapPoint(x: x, y: y, timestamp: t));

      // Random walk within room bounds
      x += (_random.nextDouble() - 0.5) * 1.2;
      y += (_random.nextDouble() - 0.5) * 1.0;
      x = x.clamp(0.2, roomWidth - 0.2);
      y = y.clamp(0.2, roomHeight - 0.2);
    }

    _sessionDistance = _computePathDistance(points);
    _positions = points;
    _positionController.add(_positions);
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

  @override
  void dispose() {
    _batteryTimer?.cancel();
    _statusController.close();
    _positionController.close();
    _playStatsController.close();
    _petMoodController.close();
    _aiReportController.close();
    super.dispose();
  }
}
