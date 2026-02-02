/// Route names and paths for the app.
/// Centralizes navigation configuration.
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String activity = '/activity';
  static const String map = '/map';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const Map<String, String> routeNames = {
    dashboard: 'Dashboard',
    activity: 'Activity',
    map: 'Map',
    reports: 'Reports',
    settings: 'Settings',
  };

  /// Tab order for bottom navigation.
  static const List<String> tabRoutes = [
    dashboard,
    activity,
    map,
    reports,
    settings,
  ];
}
