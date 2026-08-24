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

  test('Event status helpers match Laravel values', () {
    final draft = Event.fromJson({
      'id': 'evt-draft',
      'title': 'Draft workshop',
      'description': 'Hidden until published.',
      'starts_at': '2026-09-12T07:00:00+00:00',
      'location_label': 'Building A - Room 101',
      'capacity': 40,
      'spots_remaining': 40,
      'status': 'draft',
    });
    final cancelled = Event.fromJson({
      'id': 'evt-cancelled',
      'title': 'Cancelled meetup',
      'description': 'Called off.',
      'starts_at': '2026-09-12T07:00:00+00:00',
      'location_label': 'Building B - Room 204',
      'capacity': 60,
      'spots_remaining': 60,
      'status': 'cancelled',
    });

    expect(draft.isDraft, isTrue);
    expect(draft.canPublish, isTrue);
    expect(draft.canDelete, isTrue);
    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.canEdit, isFalse);
    expect(cancelled.canPublish, isFalse);
  });
}
