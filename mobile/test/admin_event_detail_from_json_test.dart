import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/admin/events/attendee.dart';
import 'package:itc_events/modules/admin/events/check_in_attempt.dart';

void main() {
  test('AdminAttendee.fromJson maps campus fields and status', () {
    final attendee = AdminAttendee.fromJson({
      'name': 'Dara Sok',
      'student_id': 'e20240001',
      'department': 'GIC',
      'year': 3,
      'ticket_status': 'checked_in',
      'issued_at': '2026-08-25T05:00:00Z',
      'checked_in_at': '2026-08-26T08:00:00Z',
    });

    expect(attendee.displayName, 'Dara Sok');
    expect(attendee.campusLine, 'e20240001 · GIC · Year 3');
    expect(attendee.ticketStatus, 'checked_in');
    expect(attendee.checkedInAt, isNotNull);
  });

  test('AdminAttendee falls back when name is empty', () {
    final attendee = AdminAttendee.fromJson({
      'name': null,
      'student_id': null,
      'department': null,
      'year': null,
      'ticket_status': 'valid',
      'issued_at': '2026-08-25T05:00:00Z',
      'checked_in_at': null,
    });

    expect(attendee.displayName, 'Unknown');
    expect(attendee.campusLine, isNull);
  });

  test('CheckInAttempt.fromJson maps attempt fields', () {
    final attempt = CheckInAttempt.fromJson({
      'id': 'att-1',
      'scanned_code': 'TKT_01TEST',
      'attendee_name': 'Dara Sok',
      'method': 'manual',
      'result': 'already_checked_in',
      'ticket_id': 'tkt-1',
      'created_at': '2026-08-26T09:00:00Z',
    });

    expect(attempt.id, 'att-1');
    expect(attempt.scannedCode, 'TKT_01TEST');
    expect(attempt.displayName, 'Dara Sok');
    expect(attempt.method, 'manual');
    expect(attempt.result, 'already_checked_in');
    expect(attempt.ticketId, 'tkt-1');
  });
}
