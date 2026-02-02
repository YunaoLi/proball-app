import 'package:flutter/material.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/models/battery_state.dart';

/// Device status card: Battery %, Mode, Connection status.
/// Modern, rounded, with soft shadow. Dark mode ready.
class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key, required this.status});

  final BallStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: status.isConnected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 28,
                    color: status.isConnected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.isConnected ? 'Connected' : 'Disconnected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: status.isConnected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.mode.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _BatteryIndicator(
                  batteryState: status.batteryState,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  const _BatteryIndicator({required this.batteryState, required this.theme});

  final BatteryState batteryState;
  final ThemeData theme;

  Color get _color {
    switch (batteryState.status) {
      case BatteryStatus.normal:
        return theme.colorScheme.primary;
      case BatteryStatus.low:
        return Colors.amber;
      case BatteryStatus.critical:
      case BatteryStatus.dead:
        return theme.colorScheme.error;
    }
  }

  IconData get _batteryIcon {
    final level = batteryState.percentage;
    return level >= 75
        ? Icons.battery_full_rounded
        : level >= 50
            ? Icons.battery_6_bar_rounded
            : level >= 25
                ? Icons.battery_4_bar_rounded
                : Icons.battery_2_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_batteryIcon, size: 22, color: _color),
        const SizedBox(width: 6),
        Text(
          '${batteryState.percentage}%',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
