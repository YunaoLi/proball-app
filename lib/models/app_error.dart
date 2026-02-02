/// Centralized app error for user-facing and debug handling.
class AppError {
  const AppError({
    required this.type,
    required this.severity,
    required this.userMessage,
    this.debugMessage,
  });

  final AppErrorType type;
  final AppErrorSeverity severity;
  final String userMessage;
  final String? debugMessage;

  @override
  String toString() => 'AppError($type, $severity: $userMessage)';
}

enum AppErrorType {
  battery,
  connection,
  logic,
  unknown,
}

enum AppErrorSeverity {
  info,
  warning,
  critical,
}
