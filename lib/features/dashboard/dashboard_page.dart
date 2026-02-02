import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/app/routes.dart';
import 'package:proballdev/core/widgets/app_scaffold.dart';
import 'package:proballdev/features/current_play_session/current_play_session_page.dart';
import 'package:proballdev/features/dashboard/dashboard_view_model.dart';
import 'package:proballdev/features/dashboard/widgets/device_status_card.dart';
import 'package:proballdev/features/dashboard/widgets/pet_mood_indicator.dart';
import 'package:proballdev/features/dashboard/widgets/play_stats_card.dart';
import 'package:proballdev/services/device_service.dart';

/// Dashboard (home) screen: device status, play stats, pet mood, CTA.
/// Modern, clean, rounded cards. Soft shadows. Apple-like spacing. Dark mode ready.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(context.read<DeviceService>()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final theme = Theme.of(context);

    return AppScaffold(
      currentRoute: AppRoutes.dashboard,
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
                      'Wicked Rolling Ball Pro',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-Powered Pet Play',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    DeviceStatusCard(status: viewModel.ballStatus),
                    const SizedBox(height: 20),
                    Text(
                      'Today\'s Stats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PlayStatsCards(stats: viewModel.recentStats),
                    const SizedBox(height: 20),
                    Text(
                      'Pet Mood',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PetMoodIndicator(mood: viewModel.currentPetMood),
                    const SizedBox(height: 32),
                    _PlayCtaButton(
                      canStart: viewModel.canStartPlay,
                      batteryDead: viewModel.batteryDead,
                      onStart: () async {
                        try {
                          await viewModel.startPlay();
                          if (context.mounted) {
                            CurrentPlaySessionPage.navigate(context);
                          }
                        } catch (_) {
                          // ErrorManager handles user-visible errors
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayCtaButton extends StatelessWidget {
  const _PlayCtaButton({
    required this.canStart,
    required this.onStart,
    this.batteryDead = false,
  });

  final bool canStart;
  final VoidCallback onStart;
  final bool batteryDead;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
        onPressed: canStart ? onStart : null,
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
    return batteryDead
        ? Tooltip(
            message: 'Battery depleted. Please charge the ball to continue.',
            child: button,
          )
        : button;
  }
}
