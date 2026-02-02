/// A point on the activity map representing ball or pet position.
class MapPoint {
  const MapPoint({
    required this.x,
    required this.y,
    required this.timestamp,
  });

  final double x;
  final double y;
  final DateTime timestamp;
}
