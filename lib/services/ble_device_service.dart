import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/discovered_device.dart';
import 'package:proballdev/models/paired_device.dart';
import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/play_session.dart';
import 'package:proballdev/models/play_stats.dart';
import 'package:proballdev/services/device_service.dart';

/// Placeholder for BLE device service.
/// UI code does NOT change when this replaces [MockDeviceService].
///
/// TODO: Add flutter_blue_plus or similar for BLE scanning/connection
/// TODO: Implement connect() — scan for ball device, pair, establish GATT
/// TODO: Implement disconnect() — release GATT, cleanup
/// TODO: Implement startRoll() — send command over BLE characteristic
/// TODO: Implement stopRoll() — send stop command
/// TODO: Implement status/statusStream — parse BLE notifications for battery, mode
/// TODO: Implement isRolling — track from BLE commands/response
/// TODO: Implement positionStream — IMU data over BLE or indoor positioning
/// TODO: Implement lastPositions — cache from positionStream
/// TODO: Implement recentStats — aggregate from sessions (or sync with backend)
/// TODO: Implement currentPetMood — from AI model or backend
/// TODO: Implement reports — from AI backend when sessions complete
/// TODO: Implement notifyListeners() — call when status/report/stats change
class BleDeviceService extends DeviceService {
  @override
  BallStatus get status => BallStatus.disconnected;

  @override
  bool get isRolling => false;

  @override
  Stream<BallStatus> get statusStream => Stream.empty();

  @override
  DateTime? get currentSessionStartTime => null;

  @override
  double get currentSessionDistance => 0;

  @override
  List<PlaySession> get recentSessions => const [];

  @override
  List<PlayStats> get recentStats => const [];

  @override
  List<AiReport> get reports => const [];

  @override
  PetMood get currentPetMood => PetMood.calm;

  @override
  Future<bool> connect() async {
    // TODO: BLE scan, connect, GATT
    throw UnimplementedError('BleDeviceService: Implement when BLE hardware is ready.');
  }

  @override
  Future<void> disconnect() async {
    // TODO: Release GATT, cleanup
    throw UnimplementedError('BleDeviceService: Implement when BLE hardware is ready.');
  }

  @override
  Future<void> startRoll() async {
    // TODO: Send roll command over BLE
    throw UnimplementedError('BleDeviceService: Implement when BLE hardware is ready.');
  }

  @override
  Future<void> stopRoll() async {
    // TODO: Send stop command over BLE
    throw UnimplementedError('BleDeviceService: Implement when BLE hardware is ready.');
  }

  @override
  Stream<List<MapPoint>> get positionStream => Stream.empty();

  @override
  List<MapPoint> get lastPositions => const [];

  @override
  Future<List<PairedDevice>> fetchMyDevices() async =>
      throw UnimplementedError('BleDeviceService: fetchMyDevices when BLE ready');

  @override
  Future<void> startScan() async {
    // TODO: BLE scan via flutter_blue_plus or similar
  }

  @override
  Future<void> stopScan() async {}

  @override
  Stream<List<DiscoveredDevice>> get discoveredStream => Stream.value([]);

  @override
  Future<Map<String, dynamic>> pairDevice({
    required String deviceId,
    String? deviceName,
  }) async =>
      throw UnimplementedError('BleDeviceService: pairDevice when BLE ready');

  @override
  Future<Map<String, dynamic>> getMe() async =>
      throw UnimplementedError('BleDeviceService: getMe when BLE ready');
}
