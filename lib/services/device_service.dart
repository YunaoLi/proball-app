import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/models/discovered_device.dart';
import 'package:proballdev/models/paired_device.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/battery_state.dart';
import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/play_session.dart';
import 'package:proballdev/models/play_stats.dart';

/// Abstract interface for ball device communication.
/// UI depends ONLY on this interface—swap [MockDeviceService] for [BleDeviceService]
/// in app.dart without changing any UI code.
abstract class DeviceService extends ChangeNotifier {
  /// Current ball status (connection, battery, mode).
  BallStatus get status;

  /// Whether the ball is currently rolling.
  bool get isRolling;

  /// Stream of ball status updates.
  Stream<BallStatus> get statusStream;

  /// Initiate connection to ball. Returns true if successful.
  Future<bool> connect();

  /// Disconnect from ball.
  Future<void> disconnect();

  /// Start rolling. Parameters will be used for AI/IMU control later.
  Future<void> startRoll();

  /// Stop rolling.
  Future<void> stopRoll();

  /// Position history for map display (mock or GPS/BLE later).
  Stream<List<MapPoint>> get positionStream;

  /// Last recorded path (from most recent session).
  List<MapPoint> get lastPositions;

  /// Start time of current in-progress session. Null when idle.
  DateTime? get currentSessionStartTime;

  /// Distance traveled in current session (meters). 0 when idle.
  double get currentSessionDistance;

  /// Completed play sessions. Updates when a session ends.
  List<PlaySession> get recentSessions;

  /// Recent stats for backward compatibility. Derived from [recentSessions].
  List<PlayStats> get recentStats;

  /// Current pet mood (e.g. from last session or AI).
  PetMood get currentPetMood;

  /// All AI reports, one per completed session. Newest first.
  List<AiReport> get reports;

  /// Most recent report, or null if none.
  AiReport? get latestReport => reports.isNotEmpty ? reports.first : null;

  /// Battery state derived from status. For UI and guards.
  BatteryState get batteryState => status.batteryState;

  /// Start BLE scan (or mock scan). Discovered devices appear on [discoveredStream].
  Future<void> startScan();

  /// Stop BLE scan.
  Future<void> stopScan();

  /// Stream of devices discovered via scan. NOT from DB — nearby devices only.
  Stream<List<DiscoveredDevice>> get discoveredStream;

  /// List devices paired to current user (from DB). Source of truth for "My Devices".
  Future<List<PairedDevice>> fetchMyDevices();

  /// Pair device with backend. Requires auth. Returns { ok, deviceId, nickname? }.
  Future<Map<String, dynamic>> pairDevice({
    required String deviceId,
    String? deviceName,
  });

  /// Get current user from backend. Returns { ok, userId, email?, name? }.
  Future<Map<String, dynamic>> getMe();
}
