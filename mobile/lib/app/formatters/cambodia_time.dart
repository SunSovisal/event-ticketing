/// Cambodia / Indochina Time. No DST, always UTC+7.
abstract final class CambodiaTime {
  static const offset = Duration(hours: 7);

  /// Instant → naive wall clock in Phnom Penh (hour/minute are ICT).
  static DateTime toWallClock(DateTime instant) {
    final ict = instant.toUtc().add(offset);
    return DateTime(
      ict.year,
      ict.month,
      ict.day,
      ict.hour,
      ict.minute,
      ict.second,
      ict.millisecond,
      ict.microsecond,
    );
  }

  /// Naive ICT wall clock → UTC instant.
  static DateTime fromWallClock(DateTime wallClock) {
    return DateTime.utc(
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
      wallClock.microsecond,
    ).subtract(offset);
  }

  static DateTime nowWallClock() => toWallClock(DateTime.now());

  static String toIso8601(DateTime wallClock) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${wallClock.year.toString().padLeft(4, '0')}-'
        '${two(wallClock.month)}-${two(wallClock.day)}T'
        '${two(wallClock.hour)}:${two(wallClock.minute)}:${two(wallClock.second)}'
        '+07:00';
  }
}
