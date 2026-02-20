import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/app/app_init.dart';
import 'package:proballdev/app/theme.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/core/widgets/error_overlay.dart';
import 'package:proballdev/core/widgets/reauth_listener.dart';
import 'package:proballdev/services/api_client.dart';
import 'package:proballdev/services/auth_service.dart';
import 'package:proballdev/services/app_state.dart';
import 'package:proballdev/services/auth_state.dart';
import 'package:proballdev/services/auth_storage.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/error_manager.dart';
import 'package:proballdev/services/mock_device_service.dart';
import 'package:proballdev/services/play_session_state.dart';
import 'package:proballdev/services/report_notifier.dart';
import 'package:proballdev/services/report_service.dart';
import 'package:proballdev/services/session_service.dart';
import 'package:proballdev/services/stats_notifier.dart';
import 'package:proballdev/services/stats_service.dart';
import 'package:proballdev/services/token_store.dart';

/// Root application widget.
/// Configures theme, tab-based navigation, and dependency injection.
///
/// To switch to real BLE: change MockDeviceService to BleDeviceService below.
/// No other UI code changes required.
class WickedRollingBallApp extends StatelessWidget {
  const WickedRollingBallApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ErrorManager>(create: (_) => ErrorManager()),
        Provider<AuthStorage>(create: (_) => AuthStorage()),
        ChangeNotifierProvider<AuthStateNotifier>(create: (_) => AuthStateNotifier()),
        ChangeNotifierProvider<PlaySessionStateNotifier>(create: (_) => PlaySessionStateNotifier()),
        ChangeNotifierProvider<TokenStore>(
          create: (_) => TokenStore(prefs),
        ),
        Provider<AuthService>(
          create: (ctx) => AuthService(
            ctx.read<TokenStore>(),
            ctx.read<AuthStorage>(),
          ),
        ),
        ChangeNotifierProvider<AppStateNotifier>(
          create: (ctx) => AppStateNotifier(ctx.read<AuthService>())..refresh(),
        ),
        Provider<ApiClient>(
          create: (ctx) => ApiClient(
            baseUrl: AppConstants.apiBaseUrl,
            tokenProvider: () => ctx.read<TokenStore>().token,
            refreshCallback: () => ctx.read<AuthService>().refresh(),
            onAuthFailureDuringPlay: () => ctx.read<AuthStateNotifier>().setApiDegraded(true),
            onAuthFailureIdle: () {
              final auth = ctx.read<AuthService>();
              final state = ctx.read<AuthStateNotifier>();
              auth.logout().then((_) => state.setNeedsReauth(true));
            },
            isPlaySessionActive: () {
              final s = ctx.read<PlaySessionStateNotifier>().state;
              return s.isActive || s.isEnding;
            },
          ),
        ),
        Provider<SessionService>(
          create: (ctx) => SessionService(ctx.read<ApiClient>()),
        ),
        Provider<ReportService>(
          create: (ctx) => ReportService(ctx.read<ApiClient>()),
        ),
        Provider<StatsService>(
          create: (ctx) => StatsService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<StatsNotifier>(
          create: (ctx) => StatsNotifier(ctx.read<StatsService>())..refresh(),
        ),
        ChangeNotifierProvider<DeviceService>(
          create: (ctx) => MockDeviceService(
            errorManager: ctx.read<ErrorManager>(),
            apiClient: ctx.read<ApiClient>(),
          ),
        ),
        ChangeNotifierProvider<ReportNotifier>(
          create: (ctx) => ReportNotifier(
            ctx.read<ReportService>(),
            ctx.read<DeviceService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Wicked Rolling Ball Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        initialRoute: '/',
        routes: {
          '/': (ctx) => ReauthListener(
            child: const ErrorOverlay(child: AppInit()),
          ),
        },
      ),
    );
  }
}
