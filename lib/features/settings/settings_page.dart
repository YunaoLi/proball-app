import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/app/routes.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/core/widgets/app_scaffold.dart';
import 'package:proballdev/features/auth/auth_page.dart';
import 'package:proballdev/models/ball_status.dart';
import 'package:proballdev/services/auth_service.dart';
import 'package:proballdev/services/device_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceService = context.watch<DeviceService>();
    final theme = Theme.of(context);

    return AppScaffold(
      currentRoute: AppRoutes.settings,
      showBottomNav: false,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        deviceService.status.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: deviceService.status.isConnected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      title: const Text('Ball Connection'),
                      subtitle: Text(
                        deviceService.status.isConnected
                            ? 'Connected • ${deviceService.status.batteryLevel}% battery • ${deviceService.status.mode.displayName}'
                            : 'Disconnected',
                      ),
                      trailing: FilledButton(
                        onPressed: () async {
                          if (deviceService.status.isConnected) {
                            await deviceService.disconnect();
                          } else {
                            await deviceService.connect();
                          }
                        },
                        child: Text(
                          deviceService.status.isConnected
                              ? 'Disconnect'
                              : 'Connect',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () async {
                    await context.read<AuthService>().logout();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(AppConstants.pairedDeviceIdKey);
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.outline),
                  title: const Text('About'),
                  subtitle: Text(AppConstants.appName),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${AppConstants.appName}\n${AppConstants.appTagline}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
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
