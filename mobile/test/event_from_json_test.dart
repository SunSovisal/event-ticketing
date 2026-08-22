import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/events/event.dart';

void main() {
  test('Event.fromJson maps public event JSON', () {
    final event = Event.fromJson({
      'id': 'evt-1',
      'title': 'Open Source Meetup',
      'description': 'Lightning talks.',
      'starts_at': '2026-09-12T07:00:00+00:00',
      'ends_at': null,
      'location_label': 'Building B - Room 204',
      'capacity': 60,
      'spots_remaining': 18,
      'status': 'published',
      'image_url': null,
    });

    expect(event.id, 'evt-1');
    expect(event.title, 'Open Source Meetup');
    expect(event.startsAt, DateTime.utc(2026, 9, 12, 7));
    expect(event.endsAt, isNull);
    expect(event.spotsRemaining, 18);
    expect(event.imageUrl, isNull);
    expect(event.isPublished, isTrue);
  });
}
