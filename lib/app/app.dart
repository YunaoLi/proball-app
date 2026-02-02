import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/app/app_shell.dart';
import 'package:proballdev/app/theme.dart';
import 'package:proballdev/core/widgets/error_overlay.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/error_manager.dart';
import 'package:proballdev/services/mock_device_service.dart';

/// Root application widget.
/// Configures theme, tab-based navigation, and dependency injection.
///
/// To switch to real BLE: change MockDeviceService to BleDeviceService below.
/// No other UI code changes required.
class WickedRollingBallApp extends StatelessWidget {
  const WickedRollingBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ErrorManager>(create: (_) => ErrorManager()),
        ChangeNotifierProvider<DeviceService>(
          create: (context) => MockDeviceService(
            errorManager: context.read<ErrorManager>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Wicked Rolling Ball Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: const ErrorOverlay(child: AppShell()),
      ),
    );
  }
}
