import 'package:flutter/material.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/models/stats.dart';

/// Aggregate play statistics: Total play time, Calories burned.
/// Two side-by-side cards. Dark mode ready. Uses [TodayStats] from API.
class PlayStatsCards extends StatelessWidget {
  const PlayStatsCards({super.key, this.todayStats, this.loading = false});

  final TodayStats? todayStats;
  final bool loading;

  String get _formattedTotalTime {
    final total = todayStats?.totalPlayTimeSec ?? 0;
    if (total == 0) return '0s';
    return DateFormatter.formatElapsedSeconds(total);
  }

  double get _totalCalories => todayStats?.totalCalories ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return Row(
        children: [
          Expanded(child: _StatCard(icon: Icons.schedule_rounded, label: 'Total Play Time', value: '—', theme: theme, isDark: isDark)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, label: 'Calories Burned', value: '—', unit: 'cal', theme: theme, isDark: isDark)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            label: 'Total Play Time',
            value: _formattedTotalTime,
            theme: theme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Calories Burned',
            value: _totalCalories.toStringAsFixed(1),
            unit: 'cal',
            theme: theme,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    required this.theme,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit.isNotEmpty ? '$value $unit' : value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
