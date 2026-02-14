import 'package:proballdev/services/api_client.dart';

/// Session API: start and end play sessions.
class SessionService {
  SessionService(this._api);

  final ApiClient _api;

  /// Start a play session. Returns { ok, sessionId, status, startedAt }.
  Future<Map<String, dynamic>> startSession(
    String deviceId, {
    int? batteryStart,
    String? firmwareVersion,
    String? startedAt,
  }) async {
    final body = <String, dynamic>{
      'deviceId': deviceId,
      if (batteryStart != null) 'batteryStart': batteryStart,
      if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
      if (startedAt != null) 'startedAt': startedAt,
    };
    return _api.post('api/sessions/start', body: body, auth: true);
  }

  /// End a session with aggregated metrics.
  /// Payload: endedAt?, durationSec, calories, batteryEnd, metrics?
  Future<Map<String, dynamic>> endSession(
    String sessionId, {
    String? endedAt,
    required int durationSec,
    required double calories,
    required int batteryEnd,
    Map<String, dynamic>? metrics,
  }) async {
    final body = <String, dynamic>{
      if (endedAt != null) 'endedAt': endedAt,
      'durationSec': durationSec,
      'calories': calories,
      'batteryEnd': batteryEnd,
      if (metrics != null) 'metrics': metrics,
    };
    return _api.post('api/sessions/$sessionId/end', body: body, auth: true);
  }
}
