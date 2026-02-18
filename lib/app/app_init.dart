import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/app/app_shell.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/features/auth/auth_page.dart';
import 'package:proballdev/features/pair/pair_page.dart';
import 'package:proballdev/services/app_state.dart';
import 'package:proballdev/services/auth_service.dart';

/// Resolves initial route based on token and paired device.
class AppInit extends StatefulWidget {
  const AppInit({super.key});

  @override
  State<AppInit> createState() => _AppInitState();
}

class _AppInitState extends State<AppInit> {
  late final Future<String> _routeFuture;

  @override
  void initState() {
    super.initState();
    _routeFuture = _resolveRoute();
  }

  Future<String> _resolveRoute() async {
    final auth = context.read<AuthService>();
    await auth.loadFromStorage();
    await context.read<AppStateNotifier>().refresh();
    if (!auth.hasToken) return '/auth';
    final prefs = await SharedPreferences.getInstance();
    final paired = prefs.getString(AppConstants.pairedDeviceIdKey);
    if (paired == null || paired.isEmpty) return '/pair';
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _routeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final route = snapshot.data!;
        if (route == '/auth') {
          return const AuthPage();
        }
        if (route == '/pair') {
          return const PairPage();
        }
        return const AppShell();
      },
    );
  }
}
