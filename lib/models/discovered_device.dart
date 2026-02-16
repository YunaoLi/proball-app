/// A device discovered via BLE scan (or mock scan).
/// NOT from DB — represents nearby devices available to pair.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.deviceId,
    this.name,
    this.rssi,
    this.isConnectable,
  });

  final String deviceId;
  final String? name;
  final int? rssi;
  final bool? isConnectable;

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json) {
    return DiscoveredDevice(
      deviceId: json['deviceId'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String?,
      rssi: json['rssi'] as int?,
      isConnectable: json['isConnectable'] as bool?,
    );
  }
}
