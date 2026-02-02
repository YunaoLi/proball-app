import 'package:flutter/material.dart';
import 'package:proballdev/app/routes.dart';

/// Main scaffold with optional bottom navigation for the app.
/// When [showBottomNav] is false (e.g. inside tab shell), only body is shown.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.currentRoute,
    required this.child,
    this.showBottomNav = true,
  });

  final String currentRoute;
  final Widget child;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
        selectedIndex: _indexForRoute(currentRoute),
              onDestinationSelected: (i) => _navigateTo(context, i),
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
            )
          : null,
    );
  }

  int _indexForRoute(String route) {
    final i = AppRoutes.tabRoutes.indexOf(route);
    return i >= 0 ? i : 0;
  }

  void _navigateTo(BuildContext context, int index) {
    final routes = AppRoutes.tabRoutes;
    if (index < routes.length) {
      Navigator.of(context).pushReplacementNamed(routes[index]);
    }
  }
}
