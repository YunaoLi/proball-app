import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/core/utils/logout_helper.dart';
import 'package:proballdev/features/activity/activity_page.dart';
import 'package:proballdev/features/dashboard/dashboard_page.dart';
import 'package:proballdev/features/map/map_page.dart';
import 'package:proballdev/features/report/ai_report_list_page.dart';
import 'package:proballdev/features/settings/settings_page.dart';
import 'package:proballdev/services/auth_state.dart';

/// Tab shell with bottom navigation. Preserves state between tabs using IndexedStack.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _pages = [
    DashboardPage(),
    ActivityPage(),
    MapPage(),
    AiReportListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<AuthStateNotifier>(),
      builder: (context, _) {
        final authState = context.read<AuthStateNotifier>();
        return Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'logout') performLogout(context);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 12),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (authState.apiDegraded)
                Material(
                  color: Colors.amber.shade100,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Session expired. Please reconnect later.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
        );
      },
    );
  }
}
