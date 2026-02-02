/// Statistics for a play session.
/// Aggregates data from ball movement and pet interaction.
class PlayStats {
  const PlayStats({
    required this.elapsedTime,
    required this.caloriesBurned,
    required this.distance,
    required this.date,
  });

  final int elapsedTime; // seconds
  final double caloriesBurned;
  final double distance; // meters
  final DateTime date;

  String get formattedElapsedTime {
    final minutes = elapsedTime ~/ 60;
    final seconds = elapsedTime % 60;
    return '${minutes}m ${seconds}s';
  }
}
