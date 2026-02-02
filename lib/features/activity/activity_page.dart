import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/app/routes.dart';
import 'package:proballdev/core/widgets/app_scaffold.dart';
import 'package:proballdev/features/activity/activity_view_model.dart';
import 'package:proballdev/features/activity/widgets/calories_chart.dart';
import 'package:proballdev/features/activity/widgets/duration_chart.dart';
import 'package:proballdev/features/activity/widgets/session_list_item.dart';
import 'package:proballdev/features/current_play_session/current_play_session_page.dart';
import 'package:proballdev/services/device_service.dart';

/// Activity page: recent sessions, calories chart, duration chart.
/// Uses mock historical data for charts. Dark mode ready.
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivityViewModel(context.read<DeviceService>()),
      child: const _ActivityView(),
    );
  }
}

class _ActivityView extends StatelessWidget {
  const _ActivityView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ActivityViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      currentRoute: AppRoutes.activity,
      showBottomNav: false,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewModel.ballStatus.isConnected
                              ? 'Ready to play'
                              : 'Connect ball in Settings',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PlayCtaSection(
                      canRoll: viewModel.canRoll,
                      onStart: () async {
                        try {
                          await viewModel.startRoll();
                          if (context.mounted) {
                            CurrentPlaySessionPage.navigate(context);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not start play. Please try again.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Calories Burned',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      theme: theme,
                      isDark: isDark,
                      child: SizedBox(
                        height: 200,
                        child: CaloriesChart(dataPoints: viewModel.caloriesHistory),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Session Duration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      theme: theme,
                      isDark: isDark,
                      child: SizedBox(
                        height: 200,
                        child: DurationChart(dataPoints: viewModel.durationHistory),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Sessions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (viewModel.recentSessions.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _EmptySessionsPlaceholder(theme: theme),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = viewModel.recentSessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SessionListItem(session: session),
                      );
                    },
                    childCount: viewModel.recentSessions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayCtaSection extends StatelessWidget {
  const _PlayCtaSection({
    required this.canRoll,
    required this.onStart,
  });

  final bool canRoll;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: canRoll ? onStart : null,
      icon: const Icon(Icons.play_arrow_rounded, size: 24),
      label: const Text('Start Play'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.theme,
    required this.isDark,
    required this.child,
  });

  final ThemeData theme;
  final bool isDark;
  final Widget child;

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
      child: child,
    );
  }
}

class _EmptySessionsPlaceholder extends StatelessWidget {
  const _EmptySessionsPlaceholder({required this.theme});

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
      child: Center(
        child: Text(
          'No play sessions yet. Start a session from the button above.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
