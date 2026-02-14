import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/core/utils/date_formatter.dart';
import 'package:proballdev/features/current_play_session/current_play_session_view_model.dart';
import 'package:proballdev/features/report/report_detail_page.dart';
import 'package:proballdev/features/map/widgets/indoor_map_widget.dart';
import 'package:proballdev/models/battery_state.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/play_session_state.dart';
import 'package:proballdev/services/report_notifier.dart';
import 'package:proballdev/services/report_service.dart';
import 'package:proballdev/services/session_service.dart';

/// Live session screen shown when play is active.
/// Large timer, real-time metrics, path map, Stop Play button.
/// On End: sends metrics to backend, navigates to report detail.
class CurrentPlaySessionPage extends StatelessWidget {
  const CurrentPlaySessionPage({super.key, required this.sessionId, required this.deviceId});

  final String sessionId;
  final String deviceId;

  static Future<void> navigate(BuildContext context, {required String sessionId, required String deviceId}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ChangeNotifierProvider(
          create: (_) => CurrentPlaySessionViewModel(
            ctx.read<DeviceService>(),
            ctx.read<SessionService>(),
            ctx.read<ReportService>(),
            sessionId: sessionId,
            deviceId: deviceId,
            playSessionState: ctx.read<PlaySessionStateNotifier>(),
            reportNotifier: ctx.read<ReportNotifier>(),
          ),
          child: CurrentPlaySessionPage(sessionId: sessionId, deviceId: deviceId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CurrentPlaySessionViewModel>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Playing',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          _BatteryChip(batteryLevel: viewModel.batteryLevel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: viewModel.elapsedListenable,
                        builder: (context, _) => _HeroTimer(
                          formatted:
                              DateFormatter.formatElapsedSeconds(viewModel.elapsedSeconds),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ListenableBuilder(
                        listenable: viewModel.elapsedListenable,
                        builder: (context, _) => _MetricsRow(
                          elapsedSeconds: viewModel.elapsedSeconds,
                          calories: viewModel.liveCalories,
                          distance: viewModel.liveDistance,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (viewModel.pathPositions.isNotEmpty) ...[
                        Text(
                          'Path',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: IndoorMapWidget(
                            positions: viewModel.pathPositions,
                            activityZones: viewModel.activityZones,
                            roomZones: CurrentPlaySessionViewModel.roomZones,
                            colorScheme: Theme.of(context).colorScheme,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            await viewModel.endAndNavigateToReport(context);
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not stop session. Please try again.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.stop_rounded, size: 24),
                        label: const Text('Stop Play'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatteryChip extends StatelessWidget {
  const _BatteryChip({required this.batteryLevel});

  final int batteryLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batteryState = BatteryState.fromPercentage(batteryLevel);
    final color = batteryState.isDead || batteryState.isCritical
        ? theme.colorScheme.error
        : batteryState.isLow
            ? Colors.amber
            : theme.colorScheme.primary;

    final icon = batteryLevel >= 75
        ? Icons.battery_full_rounded
        : batteryLevel >= 50
            ? Icons.battery_6_bar_rounded
            : batteryLevel >= 25
                ? Icons.battery_4_bar_rounded
                : Icons.battery_2_bar_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            '$batteryLevel%',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTimer extends StatelessWidget {
  const _HeroTimer({required this.formatted});

  final String formatted;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatted,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: -2,
          ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.elapsedSeconds,
    required this.calories,
    required this.distance,
  });

  final int elapsedSeconds;
  final double calories;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            theme: theme,
            isDark: isDark,
            icon: Icons.schedule_rounded,
            label: 'Time',
            value: DateFormatter.formatElapsedSeconds(elapsedSeconds),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            theme: theme,
            isDark: isDark,
            icon: Icons.local_fire_department_rounded,
            label: 'Calories',
            value: '${calories.toStringAsFixed(1)} cal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            theme: theme,
            isDark: isDark,
            icon: Icons.straighten_rounded,
            label: 'Distance',
            value: '${distance.toStringAsFixed(1)} m',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.theme,
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
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
    );
  }
}
