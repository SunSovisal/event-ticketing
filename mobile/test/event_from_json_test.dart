import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/event_payment.dart';

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
      'category': 'Meetup',
    });

    expect(event.id, 'evt-1');
    expect(event.title, 'Open Source Meetup');
    expect(event.startsAt, DateTime.utc(2026, 9, 12, 7));
    expect(event.endsAt, isNull);
    expect(event.spotsRemaining, 18);
    expect(event.imageUrl, isNull);
    expect(event.isPublished, isTrue);
    expect(event.isSaved, isFalse);
    expect(event.category, 'Meetup');
    expect(event.isFree, isTrue);
    expect(event.priceAmount, 0);
  });

  test('Event.fromJson maps a paid price', () {
    final event = Event.fromJson({
      'id': 'evt-paid',
      'title': 'Paid workshop',
      'description': 'KHQR entry.',
      'starts_at': '2026-09-12T07:00:00+00:00',
      'location_label': 'Building A - Room 101',
      'capacity': 40,
      'spots_remaining': 40,
      'status': 'published',
      'price_amount': 0.01,
      'price_currency': 'USD',
      'is_free': false,
      'payment_methods': [
        {'id': 'khqr', 'live': true, 'sandbox': false},
        {'id': 'aba_pay', 'live': false, 'sandbox': true},
      ],
    });

    expect(event.isFree, isFalse);
    expect(event.priceAmount, 0.01);
    expect(event.formattedPrice, r'$0.01');
    expect(event.hasAbaPay, isTrue);
    expect(event.availablePaymentMethods.map((method) => method.id), [
      'khqr',
      'aba_pay',
    ]);
  });

  test('Event.fromJson maps is_saved when present', () {
    final event = Event.fromJson({
      'id': 'evt-1',
      'title': 'Open Source Meetup',
      'description': 'Lightning talks.',
      'starts_at': '2026-09-12T07:00:00+00:00',
      'location_label': 'Building B - Room 204',
      'capacity': 60,
      'spots_remaining': 18,
      'status': 'published',
      'is_saved': true,
    });

    expect(event.isSaved, isTrue);
    expect(event.copyWith(isSaved: false).isSaved, isFalse);
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

  test('hasEnded matches Laravel 2-hour default end', () {
    final now = DateTime.utc(2026, 8, 24, 10);
    final ended = Event.fromJson({
      'id': 'evt-ended',
      'title': 'Past workshop',
      'description': 'Already finished.',
      'starts_at': '2026-08-24T07:00:00+00:00',
      'location_label': 'Building A - Room 101',
      'capacity': 40,
      'spots_remaining': 4,
      'status': 'published',
    });
    final upcoming = Event.fromJson({
      'id': 'evt-upcoming',
      'title': 'Later workshop',
      'description': 'Still ahead.',
      'starts_at': '2026-08-24T12:00:00+00:00',
      'location_label': 'Building A - Room 101',
      'capacity': 40,
      'spots_remaining': 40,
      'status': 'published',
    });

    expect(ended.hasEnded(now), isTrue);
    expect(upcoming.hasEnded(now), isFalse);
  });

  test('EventPayment.fromJson maps a PayWay ABA deeplink', () {
    final payment = EventPayment.fromJson({
      'id': 'pay-1',
      'event_id': 'evt-1',
      'status': 'pending',
      'amount': 0.01,
      'currency': 'USD',
      'qr_md5': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'qr_code': '000201PAYWAY',
      'aba_deeplink':
          'abamobilebank://ababank.com?type=payway&qrcode=000201PAYWAY',
      'method': 'aba_pay',
      'qr_expires_at': '2026-09-10T12:00:00+00:00',
    });

    expect(payment.abaDeeplink, startsWith('abamobilebank://ababank.com?type=payway'));
    expect(payment.qrCode, '000201PAYWAY');
    expect(payment.isPending, isTrue);
    expect(payment.isAbaPay, isTrue);
  });
}
