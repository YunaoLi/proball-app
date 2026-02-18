import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/features/report/widgets/recommendations_list.dart';
import 'package:proballdev/features/report/widgets/stats_grid.dart';
import 'package:proballdev/models/report_content.dart';

/// Strava-style activity card for a single AI report.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.theme,
    required this.content,
    this.showDebugPanel = false,
  });

  final ThemeData theme;
  final ReportContent content;
  final bool showDebugPanel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          theme: theme,
          title: content.summaryTitle,
          generatedAt: content.generatedAt,
        ),
        const SizedBox(height: 16),
        Text(
          content.summary,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _HighlightsSection(
          theme: theme,
          highlights: content.highlights,
        ),
        const SizedBox(height: 20),
        StatsGrid(theme: theme, stats: content.stats),
        const SizedBox(height: 24),
        RecommendationsList(
          theme: theme,
          recommendations: content.recommendations,
        ),
        if (showDebugPanel) ...[
          const SizedBox(height: 24),
          _DebugPanel(content: content),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.title,
    required this.generatedAt,
  });

  final ThemeData theme;
  final String title;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title.isNotEmpty ? title : 'Session Report',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          DateFormatter.formatReportDate(generatedAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection({
    required this.theme,
    required this.highlights,
  });

  final ThemeData theme;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Highlights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      h,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.content});

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final json = {
      'summaryTitle': content.summaryTitle,
      'summary': content.summary,
      'highlights': content.highlights,
      'stats': {
        'durationSec': content.stats.durationSec,
        'calories': content.stats.calories,
        'batteryDelta': content.stats.batteryDelta,
      },
      'recommendations': content.recommendations,
      'generatedAt': content.generatedAt.toIso8601String(),
    };
    final pretty = const JsonEncoder.withIndent('  ').convert(json);
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        'Details (dev)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            pretty,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
