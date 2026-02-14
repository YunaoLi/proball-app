import 'dart:async';

import 'package:proballdev/models/app_error.dart';
import 'package:proballdev/services/api_client.dart';

/// Report API: list reports, get by session, poll until READY.
class ReportService {
  ReportService(this._api);

  final ApiClient _api;

  /// List last 50 reports. Returns { ok, reports: [...] }.
  Future<Map<String, dynamic>> listReports() async {
    return _api.get('api/reports', auth: true);
  }

  /// Get report by sessionId. Returns { ok, status, content?, failureReason? }.
  Future<Map<String, dynamic>> getReport(String sessionId) async {
    return _api.get('api/reports/$sessionId', auth: true);
  }

  /// Poll until status is READY, FAILED, or timeout.
  /// Returns final report map. Throws AppError on timeout.
  Future<Map<String, dynamic>> pollReport(
    String sessionId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final res = await getReport(sessionId);
      final status = res['status'] as String?;
      if (status == 'READY' || status == 'FAILED') return res;
      await Future<void>.delayed(interval);
    }
    throw AppError(
      type: AppErrorType.unknown,
      severity: AppErrorSeverity.warning,
      userMessage: 'Report is still generating. Please check back later.',
    );
  }
}
