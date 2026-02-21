import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/features/activity/activity_view_model.dart';

const _unit = 'min';

double _computeMaxY(List<ChartDataPoint> dataPoints) {
  if (dataPoints.isEmpty) return 15.0;
  final maxVal = dataPoints.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);
  return (maxVal * 1.2).clamp(5.0, 180.0);
}

double _computeInterval(double maxY) {
  if (maxY <= 5) return 1;
  if (maxY <= 10) return 2;
  if (maxY <= 20) return 5;
  if (maxY <= 60) return 10;
  if (maxY <= 120) return 30;
  return 60;
}

/// Bar chart: Session duration (minutes) over time (last 7 days). Y-axis in min.
class DurationChart extends StatelessWidget {
  const DurationChart({super.key, required this.dataPoints});

  final List<ChartDataPoint> dataPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    final maxY = _computeMaxY(dataPoints);
    final interval = _computeInterval(maxY);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: dataPoints.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: p.value,
                color: color,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final v = value.toInt();
                if (v < 0 || v > maxY) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '$v $_unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < dataPoints.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dataPoints[i].label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= dataPoints.length) return null;
              final label = dataPoints[groupIndex].label;
              final totalSec = (rod.toY * 60).round();
              final valueStr = DateFormatter.formatDuration(totalSec);
              return BarTooltipItem(
                '$label • $valueStr',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
