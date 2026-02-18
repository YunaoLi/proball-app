import 'package:flutter/material.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/models/report_content.dart';

/// Strava-style 2-column stats grid: Duration, Calories, Battery delta.
class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.theme,
    required this.stats,
  });

  final ThemeData theme;
  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 280;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCell(
              theme: theme,
              icon: Icons.schedule_rounded,
              label: 'Duration',
              value: DateFormatter.formatDuration(stats.durationSec),
            ),
            _StatCell(
              theme: theme,
              icon: Icons.local_fire_department_rounded,
              label: 'Calories',
              value: stats.calories != null
                  ? '${stats.calories!.toStringAsFixed(1)} cal'
                  : '—',
            ),
            _StatCell(
              theme: theme,
              icon: Icons.battery_charging_full_rounded,
              label: 'Battery',
              value: stats.batteryDelta != null
                  ? '${stats.batteryDelta! > 0 ? '+' : ''}${stats.batteryDelta}%'
                  : '—',
            ),
          ],
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
