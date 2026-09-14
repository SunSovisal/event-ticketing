import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/app/formatters/cambodia_time.dart';
import 'package:itc_events/app/formatters/event_date.dart';

void main() {
  test('wall clock is always UTC+7, even if the instant is UTC', () {
    final instant = DateTime.utc(2026, 9, 13, 9, 34);
    final wall = CambodiaTime.toWallClock(instant);

    expect(wall.hour, 16);
    expect(wall.minute, 34);
    expect(CambodiaTime.toIso8601(wall), '2026-09-13T16:34:00+07:00');
    expect(CambodiaTime.fromWallClock(wall), instant);
  });

  test('EventDate time range uses Cambodia hours', () {
    expect(
      EventDate.formatTimeRange(DateTime.utc(2026, 9, 12, 7), null),
      '14:00 – 16:00',
    );
  });
}
