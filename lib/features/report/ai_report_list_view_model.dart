import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/services/device_service.dart';
import 'package:proballdev/services/report_service.dart';

/// View model for the AI Report list screen.
/// Fetches reports from backend API. Falls back to DeviceService for offline/mock.
class AiReportListViewModel extends ChangeNotifier {
  AiReportListViewModel(this._deviceService, this._reportService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
    loadReports();
  }

  final DeviceService _deviceService;
  final ReportService _reportService;

  List<AiReport> _reports = [];
  List<AiReport> get reports => _reports;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadReports() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _reportService.listReports();
      final list = res['reports'] as List<dynamic>? ?? [];
      _reports = list
          .map((e) => AiReport.fromListJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _reports = _deviceService.reports;
    }
    _loading = false;
    notifyListeners();
  }

  void _onDeviceServiceUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    super.dispose();
  }
}
