import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/report_service.dart';

/// Holds report list, refreshes from API, polls when any report is PENDING.
class ReportNotifier extends ChangeNotifier {
  ReportNotifier(this._reportService, this._deviceService) {
    _deviceService.addListener(_onDeviceUpdate);
  }

  final ReportService _reportService;
  final DeviceService _deviceService;

  List<AiReport> _reports = [];
  List<AiReport> get reports => List.unmodifiable(_reports);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 3);

  bool get hasAnyPending =>
      _reports.any((r) => r.status == 'PENDING' || r.status == null);

  void _onDeviceUpdate() {
    notifyListeners();
  }

  /// Refresh reports from API. Call after end-session.
  Future<void> refreshReports() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _reportService.listReports();
      final list = res['reports'] as List<dynamic>? ?? [];
      _reports = list
          .map((e) => AiReport.fromListJson(e as Map<String, dynamic>))
          .toList();
      _maybeStartPolling();
    } catch (_) {
      _reports = _deviceService.reports;
      _maybeStartPolling();
    }
    _loading = false;
    notifyListeners();
  }

  void _maybeStartPolling() {
    if (hasAnyPending) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => _pollOnce());
    } else {
      _stopPolling();
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (!hasAnyPending) {
      _stopPolling();
      return;
    }
    try {
      final res = await _reportService.listReports();
      final list = res['reports'] as List<dynamic>? ?? [];
      final updated = list
          .map((e) => AiReport.fromListJson(e as Map<String, dynamic>))
          .toList();
      final stillHasPending =
          updated.any((r) => r.status == 'PENDING' || r.status == null);
      _reports = updated;
      if (!stillHasPending) {
        _stopPolling();
      }
      notifyListeners();
    } catch (_) {
      // Ignore poll errors
    }
  }

  /// Call when reports screen becomes visible to start polling if needed.
  void startPollingIfNeeded() {
    if (hasAnyPending) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => _pollOnce());
    }
  }

  /// Call when leaving reports screen to stop polling.
  void stopPolling() {
    _stopPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _deviceService.removeListener(_onDeviceUpdate);
    super.dispose();
  }
}
