/// A device discovered via BLE scan (or mock scan).
/// Used for the Pair Device screen list.
class ScannedDevice {
  const ScannedDevice({
    required this.id,
    this.name,
  });

  final String id;
  final String? name;
}
