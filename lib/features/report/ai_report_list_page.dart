import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/app/routes.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/core/widgets/app_scaffold.dart';
import 'package:proballdev/features/report/ai_report_detail_page.dart';
import 'package:proballdev/features/report/ai_report_list_view_model.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/models/pet_mood.dart';
import 'package:proballdev/services/device_service.dart';

/// AI Report list: history of play sessions with intelligent feedback.
/// Tap a report to view full detail.
class AiReportListPage extends StatelessWidget {
  const AiReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiReportListViewModel(context.read<DeviceService>()),
      child: const _AiReportListView(),
    );
  }
}

class _AiReportListView extends StatelessWidget {
  const _AiReportListView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AiReportListViewModel>();
    final theme = Theme.of(context);
    final reports = viewModel.reports;

    return AppScaffold(
      currentRoute: AppRoutes.reports,
      showBottomNav: false,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reports',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'How your pet played, with intelligent feedback',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
              ),
            ),
          ),
            if (reports.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _EmptyReportsPlaceholder(theme: theme),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = reports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReportListTile(
                          report: report,
                          onTap: () => _openDetail(context, report),
                          theme: theme,
                        ),
                      );
                    },
                    childCount: reports.length,
                  ),
                ),
              ),
        ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, AiReport report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiReportDetailPage(report: report),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({
    required this.report,
    required this.onTap,
    required this.theme,
  });

  final AiReport report;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _moodColor(report.mood).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    report.mood.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.formatSessionDate(report.timestamp),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(report),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AiReport report) {
    final parts = <String>[];
    if (report.elapsedSeconds != null) {
      parts.add(report.formattedDuration);
    }
    if (report.caloriesBurned != null) {
      parts.add('${report.caloriesBurned!.toStringAsFixed(1)} cal');
    }
    parts.add(report.mood.displayName);
    return parts.join(' • ');
  }

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
}

class _EmptyReportsPlaceholder extends StatelessWidget {
  const _EmptyReportsPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a play session to get intelligent feedback on how your pet played.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
