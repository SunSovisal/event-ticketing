import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/check_in/check_in_outcome.dart';
import 'package:itc_events/modules/tickets/ticket.dart';

void main() {
  final ticket = Ticket.fromJson({
    'id': 'tkt-1',
    'event_id': 'evt-1',
    'ticket_code': 'TKT_01TEST',
    'status': 'checked_in',
    'checked_in_at': '2026-09-04T03:00:00Z',
    'event': {
      'id': 'evt-1',
      'title': 'Campus Fair',
      'starts_at': '2026-09-04T04:00:00Z',
      'location_label': 'Main Hall',
      'status': 'published',
    },
  });

  test('fromTicket maps a successful check-in', () {
    final outcome = CheckInOutcome.fromTicket(
      ticket,
      method: 'qr',
      attendeeName: 'Dara Sok',
    );

    expect(outcome.isSuccess, isTrue);
    expect(outcome.result, 'success');
    expect(outcome.ticketCode, 'TKT_01TEST');
    expect(outcome.eventTitle, 'Campus Fair');
    expect(outcome.attendeeName, 'Dara Sok');
    expect(outcome.method, 'qr');
  });

  test('fromApiException maps known check-in failures', () {
    final outcome = CheckInOutcome.fromApiException(
      ApiException(
        'Ticket already checked in.',
        statusCode: 409,
        code: 'ALREADY_CHECKED_IN',
        fields: {'checked_in_at': '2026-09-04T03:00:00Z'},
      ),
      ticketCode: 'TKT_01TEST',
      method: 'manual',
    );

    expect(outcome, isNotNull);
    expect(outcome!.isSuccess, isFalse);
    expect(outcome.result, 'already_checked_in');
    expect(outcome.method, 'manual');
    expect(outcome.checkedInAt, DateTime.parse('2026-09-04T03:00:00Z').toUtc());
  });

  test('fromApiException ignores transport errors', () {
    final outcome = CheckInOutcome.fromApiException(
      ApiException('Not signed in', statusCode: 401),
      ticketCode: 'TKT_01TEST',
      method: 'qr',
    );

    expect(outcome, isNull);
  });
}
