import 'package:flutter/foundation.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/services/device_service.dart';

/// View model for the AI Report list screen.
/// Provides all reports from [DeviceService]; one per completed session.
class AiReportListViewModel extends ChangeNotifier {
  AiReportListViewModel(this._deviceService) {
    _deviceService.addListener(_onDeviceServiceUpdate);
  }

  final DeviceService _deviceService;

  List<AiReport> get reports => _deviceService.reports;

  void _onDeviceServiceUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceServiceUpdate);
    super.dispose();
  }
}
