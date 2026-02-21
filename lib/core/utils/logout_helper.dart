import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/core/widgets/reauth_listener.dart';
import 'package:proballdev/services/app_state.dart';
import 'package:proballdev/services/auth_service.dart';
import 'package:proballdev/services/auth_state.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/play_session_state.dart';
import 'package:proballdev/services/report_notifier.dart';

/// Performs full logout: clear auth, paired device, navigate to root.
/// If user is in ACTIVE play session, shows confirmation modal first.
Future<void> performLogout(BuildContext context) async {
  final playState = context.read<PlaySessionStateNotifier>();
  if (playState.state.isActive || playState.state.isEnding) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout during active session?'),
        content: const Text(
          "You're currently in an active session. Logging out will stop syncing to server. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }

  playState.setIdle();
  final reportNotifier = context.read<ReportNotifier>();
  final deviceService = context.read<DeviceService>();
  final authState = context.read<AuthStateNotifier>();
  final authService = context.read<AuthService>();
  final navigator = Navigator.of(context);

  reportNotifier.stopPolling();
  await deviceService.disconnect();
  authState.clearApiDegraded();
  await authService.logout();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(AppConstants.pairedDeviceIdKey);
  await prefs.remove(AppConstants.lastSyncedTimezoneKey);
  await context.read<AppStateNotifier>().refresh();

  ReauthListener.recordReauthNavigation();
  navigator.pushNamedAndRemoveUntil('/', (_) => false);
}
