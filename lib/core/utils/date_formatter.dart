/// Date and time formatting utilities.
class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static String formatSessionDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(sessionDay).inDays;

    final time = formatTime(local);
    if (diff == 0) return 'Today $time';
    if (diff == 1) return 'Yesterday $time';
    if (diff < 7) return '${_weekday(local)} $time';
    return formatDate(local);
  }

  static String _weekday(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Format as "Feb 18 · 1:51 PM" for report cards.
  /// Converts UTC timestamps to user's local timezone for display.
  static String formatReportDate(DateTime date) {
    final local = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = local.hour;
    final minute = local.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${months[local.month - 1]} ${local.day} · $h12:${minute.toString().padLeft(2, '0')} $ampm';
  }

  /// Format duration as mm:ss for stats grid.
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formats elapsed seconds for session display.
  /// - If elapsed < 1 min → "Xs"
  /// - If elapsed < 1 hour → "Mm Ss"
  /// - If elapsed ≥ 1 hour → "Hh Mm Ss"
  static String formatElapsedSeconds(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    if (totalSeconds < 3600) {
      final m = totalSeconds ~/ 60;
      final s = totalSeconds % 60;
      return '${m}m ${s}s';
    }
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h}h ${m}m ${s}s';
  }
}
