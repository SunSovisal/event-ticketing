import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/ticket.dart';

void main() {
  final upcomingEvent = Event(
    id: 'evt-1',
    title: 'Campus Fair',
    description: 'Open day.',
    startsAt: DateTime.now().toUtc().add(const Duration(days: 3)),
    locationLabel: 'Main Hall',
    capacity: 100,
    spotsRemaining: 40,
    status: 'published',
  );

  test('Ticket.fromJson maps API fields', () {
    final ticket = Ticket.fromJson({
      'id': 'tkt-1',
      'event_id': 'evt-1',
      'ticket_code': 'TKT_01TESTCODE',
      'status': 'valid',
      'checked_in_at': null,
      'created_at': '2026-08-25T05:00:00Z',
      'event': {
        'id': 'evt-1',
        'title': 'Campus Fair',
        'starts_at': upcomingEvent.startsAt.toIso8601String(),
        'ends_at': null,
        'location_label': 'Main Hall',
        'status': 'published',
        'image_url': null,
      },
    });

    expect(ticket.id, 'tkt-1');
    expect(ticket.ticketCode, 'TKT_01TESTCODE');
    expect(ticket.isUpcoming, isTrue);
    expect(ticket.isPast, isFalse);
    expect(ticket.isCancelled, isFalse);
    expect(ticket.event.title, 'Campus Fair');
  });

  test('cancelled event marks ticket cancelled', () {
    final ticket = Ticket.fromJson({
      'id': 'tkt-2',
      'event_id': 'evt-2',
      'ticket_code': 'TKT_02',
      'status': 'valid',
      'event': {
        'id': 'evt-2',
        'title': 'Cancelled Talk',
        'starts_at': upcomingEvent.startsAt.toIso8601String(),
        'location_label': 'Room 1',
        'status': 'cancelled',
      },
    });

    expect(ticket.isCancelled, isTrue);
    expect(ticket.isUpcoming, isFalse);
  });

  test('checked_in ticket is past, not upcoming', () {
    final ticket = Ticket.fromJson({
      'id': 'tkt-3',
      'event_id': 'evt-1',
      'ticket_code': 'TKT_03',
      'status': 'checked_in',
      'checked_in_at': '2026-08-25T08:00:00Z',
      'event': {
        'id': 'evt-1',
        'title': 'Campus Fair',
        'starts_at': upcomingEvent.startsAt.toIso8601String(),
        'location_label': 'Main Hall',
        'status': 'published',
      },
    });

    expect(ticket.isCheckedIn, isTrue);
    expect(ticket.isUpcoming, isFalse);
    expect(ticket.isPast, isTrue);
  });
}
