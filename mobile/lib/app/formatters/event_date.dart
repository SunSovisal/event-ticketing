abstract final class EventDate {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Formats a UTC instant in the device local timezone, e.g. `Mon, 24 Aug · 14:00`.
  static String format(DateTime utc) {
    final local = utc.toLocal();
    final weekday = _weekdays[local.weekday - 1];
    final month = _months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$weekday, ${local.day} $month · $hour:$minute';
  }

  /// Short date for detail tiles, e.g. `14 Aug 2026`.
  static String formatShort(DateTime utc) {
    final local = utc.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  /// Time range for detail tiles, e.g. `14:00 – 16:00`.
  static String formatTimeRange(DateTime startsAtUtc, DateTime? endsAtUtc) {
    final start = startsAtUtc.toLocal();
    final end = (endsAtUtc ?? startsAtUtc.add(const Duration(hours: 2))).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)} – ${two(end.hour)}:${two(end.minute)}';
  }
}
