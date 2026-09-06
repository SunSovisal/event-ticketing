import 'package:get/get.dart';

abstract final class EventDate {
  static const _monthKeys = [
    'month_jan',
    'month_feb',
    'month_mar',
    'month_apr',
    'month_may',
    'month_jun',
    'month_jul',
    'month_aug',
    'month_sep',
    'month_oct',
    'month_nov',
    'month_dec',
  ];

  static const _weekdayKeys = [
    'weekday_mon',
    'weekday_tue',
    'weekday_wed',
    'weekday_thu',
    'weekday_fri',
    'weekday_sat',
    'weekday_sun',
  ];

  /// Formats a UTC instant in the device local timezone, e.g. `Mon, 24 Aug · 14:00`.
  static String format(DateTime utc) {
    final local = utc.toLocal();
    final weekday = _weekdayKeys[local.weekday - 1].tr;
    final month = _monthKeys[local.month - 1].tr;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$weekday, ${local.day} $month · $hour:$minute';
  }

  /// Short date for detail tiles, e.g. `14 Aug 2026`.
  static String formatShort(DateTime utc) {
    final local = utc.toLocal();
    return '${local.day} ${_monthKeys[local.month - 1].tr} ${local.year}';
  }

  /// Time range for detail tiles, e.g. `14:00 – 16:00`.
  static String formatTimeRange(DateTime startsAtUtc, DateTime? endsAtUtc) {
    final start = startsAtUtc.toLocal();
    final end = (endsAtUtc ?? startsAtUtc.add(const Duration(hours: 2)))
        .toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)} – ${two(end.hour)}:${two(end.minute)}';
  }
}
