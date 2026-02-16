/// A device paired to the current user (from GET /api/devices).
class PairedDevice {
  const PairedDevice({
    required this.deviceId,
    this.nickname,
    this.model,
    this.firmwareVersion,
    this.pairedAt,
  });

  final String deviceId;
  final String? nickname;
  final String? model;
  final String? firmwareVersion;
  final String? pairedAt;

  factory PairedDevice.fromJson(Map<String, dynamic> json) {
    return PairedDevice(
      deviceId: json['deviceId'] as String? ?? '',
      nickname: json['nickname'] as String?,
      model: json['model'] as String?,
      firmwareVersion: json['firmwareVersion'] as String?,
      pairedAt: json['pairedAt'] as String?,
    );
  }

  static List<PairedDevice> fromList(dynamic list) {
    if (list == null || list is! List) return [];
    return list
        .map((e) => PairedDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
