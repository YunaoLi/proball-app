import 'package:proballdev/models/battery_state.dart';

/// Represents the current status of the Wicked Rolling Ball Pro device.
/// Used for UI display and device service responses.
class BallStatus {
  const BallStatus({
    required this.batteryLevel,
    required this.mode,
    required this.isConnected,
  });

  final int batteryLevel; // 0-100
  final BallMode mode;
  final bool isConnected;

  BallStatus copyWith({
    int? batteryLevel,
    BallMode? mode,
    bool? isConnected,
  }) {
    return BallStatus(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      mode: mode ?? this.mode,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  static const disconnected = BallStatus(
    batteryLevel: 0,
    mode: BallMode.normal,
    isConnected: false,
  );

  /// Derived battery state for UI and logic.
  /// When not connected, returns unknown (no reading).
  BatteryState get batteryState =>
      isConnected ? BatteryState.fromPercentage(batteryLevel) : BatteryState.unknown;
}

/// Ball operating mode.
enum BallMode {
  comfort,
  normal,
  crazy,
}

extension BallModeExtension on BallMode {
  String get displayName {
    switch (this) {
      case BallMode.comfort:
        return 'Comfort';
      case BallMode.normal:
        return 'Normal';
      case BallMode.crazy:
        return 'Crazy';
    }
  }
}
