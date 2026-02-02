import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/features/map/map_view_model.dart';
import 'package:proballdev/features/map/widgets/indoor_map_widget.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/models/map_point.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/models/play_session.dart';
import 'package:proballdev/services/device_service.dart';

/// Detail view for a single AI report. "This session" framing.
class AiReportDetailPage extends StatelessWidget {
  const AiReportDetailPage({super.key, required this.report});

  final AiReport report;

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceService>();
    final matching = deviceService.recentSessions
        .where((s) => s.sessionId == report.sessionId)
        .toList();
    final session = matching.isEmpty ? null : matching.first;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('This Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatter.formatSessionDate(report.timestamp),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _SessionOverviewCard(
                theme: theme,
                isDark: isDark,
                report: report,
                session: session,
              ),
              const SizedBox(height: 20),
              if (report.insight != null) ...[
                _AiInsightCard(
                  theme: theme,
                  isDark: isDark,
                  insight: report.insight!,
                ),
                const SizedBox(height: 20),
              ],
              _SessionSummaryCard(
                theme: theme,
                isDark: isDark,
                report: report,
              ),
              const SizedBox(height: 20),
              _MoodAndConfidenceCard(
                theme: theme,
                isDark: isDark,
                report: report,
              ),
              if (session != null && session.pathData.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Session Path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: IndoorMapWidget(
                    positions: session.pathData,
                    activityZones: _computeActivityZones(session.pathData),
                    roomZones: MapViewModel.roomZones,
                    colorScheme: theme.colorScheme,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<ActivityZone> _computeActivityZones(List<MapPoint> positions) {
    if (positions.length < 2) return [];
    const gridSize = 4;
    const roomW = 5.0;
    const roomH = 4.0;
    final cellW = roomW / gridSize;
    final cellH = roomH / gridSize;
    final counts = List.filled(gridSize * gridSize, 0);

    for (final p in positions) {
      final col = ((p.x / roomW) * gridSize).floor().clamp(0, gridSize - 1);
      final row = ((p.y / roomH) * gridSize).floor().clamp(0, gridSize - 1);
      counts[row * gridSize + col]++;
    }

    final maxCount = counts.fold<int>(0, (max, c) => c > max ? c : max);
    if (maxCount == 0) return [];

    final zones = <ActivityZone>[];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final i = r * gridSize + c;
        if (counts[i] > 0) {
          zones.add(ActivityZone(
            x: (c + 0.5) * cellW,
            y: (r + 0.5) * cellH,
            count: counts[i].toDouble(),
            intensity: (counts[i] / maxCount).clamp(0.2, 1.0),
          ));
        }
      }
    }
    return zones;
  }
}

class _SessionOverviewCard extends StatelessWidget {
  const _SessionOverviewCard({
    required this.theme,
    required this.isDark,
    required this.report,
    this.session,
  });

  final ThemeData theme;
  final bool isDark;
  final AiReport report;
  final PlaySession? session;

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
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'This Session',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (report.elapsedSeconds != null)
                Expanded(
                  child: _StatItem(
                    theme: theme,
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    value: report.formattedDuration,
                  ),
                ),
              if (report.elapsedSeconds != null && report.caloriesBurned != null)
                const SizedBox(width: 16),
              if (report.caloriesBurned != null)
                Expanded(
                  child: _StatItem(
                    theme: theme,
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calories',
                    value: '${report.caloriesBurned!.toStringAsFixed(1)} cal',
                  ),
                ),
              if ((report.elapsedSeconds != null || report.caloriesBurned != null) &&
                  report.distance != null)
                const SizedBox(width: 16),
              if (report.distance != null)
                Expanded(
                  child: _StatItem(
                    theme: theme,
                    icon: Icons.straighten_rounded,
                    label: 'Distance',
                    value: '${report.distance!.toStringAsFixed(1)} m',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.theme,
    required this.isDark,
    required this.insight,
  });

  final ThemeData theme;
  final bool isDark;
  final String insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({
    required this.theme,
    required this.isDark,
    required this.report,
  });

  final ThemeData theme;
  final bool isDark;
  final AiReport report;

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
          Row(
            children: [
              Icon(
                Icons.summarize_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.summaryText,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodAndConfidenceCard extends StatelessWidget {
  const _MoodAndConfidenceCard({
    required this.theme,
    required this.isDark,
    required this.report,
  });

  final ThemeData theme;
  final bool isDark;
  final AiReport report;

  Color _moodColor(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return const Color(0xFF10B981);
      case PetMood.excited:
        return const Color(0xFFF59E0B);
      case PetMood.calm:
        return const Color(0xFF3B82F6);
      case PetMood.lazy:
        return const Color(0xFF8B5CF6);
      case PetMood.aggressive:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _moodColor(report.mood);

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
          Row(
            children: [
              Icon(
                Icons.pets_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Mood',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          report.mood.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          report.mood.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: moodColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confidence',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(report.confidence * 100).toInt()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: report.confidence,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
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
    );
  }
}
