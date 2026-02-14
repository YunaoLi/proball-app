/// Centralized app error for user-facing and debug handling.
/// Maps backend API errors { ok: false, code, message } and HTTP errors.
class AppError {
  const AppError({
    required this.type,
    required this.severity,
    required this.userMessage,
    this.debugMessage,
    this.apiCode,
    this.httpStatus,
  });

  final AppErrorType type;
  final AppErrorSeverity severity;
  final String userMessage;
  final String? debugMessage;
  final String? apiCode;
  final int? httpStatus;

  /// Create from backend API error envelope { ok: false, code, message }.
  factory AppError.fromApiResponse(
    Map<String, dynamic> json, {
    int? httpStatus,
  }) {
    final code = json['code'] as String? ?? 'unknown';
    final message = json['message'] as String? ?? 'An error occurred';
    final severity = httpStatus == 401 || httpStatus == 403
        ? AppErrorSeverity.critical
        : AppErrorSeverity.warning;
    return AppError(
      type: AppErrorType.unknown,
      severity: severity,
      userMessage: message,
      apiCode: code,
      httpStatus: httpStatus,
    );
  }

  /// Create for non-JSON HTTP errors (e.g. network, 500 HTML).
  factory AppError.fromHttp(int status, [String? fallbackMessage]) {
    final message = fallbackMessage ??
        (status == 401
            ? 'Session expired. Please log in again.'
            : status == 403
                ? 'Access denied.'
                : status >= 500
                    ? 'Server error. Please try again later.'
                    : 'Request failed.');
    return AppError(
      type: AppErrorType.unknown,
      severity: status >= 500 ? AppErrorSeverity.critical : AppErrorSeverity.warning,
      userMessage: message,
      httpStatus: status,
    );
  }

  bool get isUnauthorized => apiCode == 'unauthorized' || httpStatus == 401;

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
