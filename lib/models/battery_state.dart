/// Unified battery state for UI and logic.
/// Reactive; designed for BLE-driven updates later.
class BatteryState {
  const BatteryState({
    required this.percentage,
    required this.status,
  }) : assert(percentage >= 0 && percentage <= 100, 'percentage must be 0–100');

  final int percentage; // 0–100
  final BatteryStatus status;

  /// Derives status from percentage.
  /// - normal: ≥ 20%
  /// - low: 10%–19%
  /// - critical: 1%–9%
  /// - dead: 0%
  factory BatteryState.fromPercentage(int percentage) {
    final clamped = percentage.clamp(0, 100);
    final status = clamped == 0
        ? BatteryStatus.dead
        : clamped <= 9
            ? BatteryStatus.critical
            : clamped <= 19
                ? BatteryStatus.low
                : BatteryStatus.normal;
    return BatteryState(percentage: clamped, status: status);
  }

  bool get isDead => status == BatteryStatus.dead;
  bool get isCritical => status == BatteryStatus.critical;
  bool get isLow => status == BatteryStatus.low;
  bool get isNormal => status == BatteryStatus.normal;

  bool get canStartPlay => !isDead;
}

enum BatteryStatus {
  normal,
  low,
  critical,
  dead,
}

extension BatteryStatusExtension on BatteryStatus {
  String get displayName {
    switch (this) {
      case BatteryStatus.normal:
        return 'Normal';
      case BatteryStatus.low:
        return 'Low';
      case BatteryStatus.critical:
        return 'Critical';
      case BatteryStatus.dead:
        return 'Dead';
    }
  }
}
