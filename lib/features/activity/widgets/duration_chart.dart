import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:proballdev/features/activity/activity_view_model.dart';

/// Bar chart: Session duration (minutes) over time (last 7 days).
/// Mock historical data. Dark mode ready.
class DurationChart extends StatelessWidget {
  const DurationChart({super.key, required this.dataPoints});

  final List<ChartDataPoint> dataPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    final maxY = dataPoints.isEmpty
        ? 15.0
        : (dataPoints.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b) * 1.2)
            .clamp(10.0, 60.0);

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
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
