import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/tickets/ticket.dart';

/// Result of `POST /admin/check-in` after mapping HTTP success/error to a UI row.
class CheckInOutcome {
  const CheckInOutcome({
    required this.result,
    required this.ticketCode,
    required this.method,
    required this.message,
    this.eventTitle,
    this.attendeeName,
    this.checkedInAt,
  });

  /// Matches `check_in_attempts.result` (success, already_checked_in, not_found, …).
  final String result;
  final String ticketCode;
  final String method;
  final String message;
  final String? eventTitle;
  final String? attendeeName;
  final DateTime? checkedInAt;

  bool get isSuccess => result == 'success';

  static const Map<String, String> errorCodes = {
    'INVALID_TICKET': 'not_found',
    'ALREADY_CHECKED_IN': 'already_checked_in',
    'TICKET_CANCELLED': 'cancelled',
    'EVENT_CANCELLED': 'event_cancelled',
    'TOO_EARLY': 'too_early',
    'TOO_LATE': 'too_late',
  };

  factory CheckInOutcome.fromTicket(
    Ticket ticket, {
    required String method,
    String? attendeeName,
  }) {
    return CheckInOutcome(
      result: 'success',
      ticketCode: ticket.ticketCode,
      method: method,
      message: 'Checked in successfully.',
      eventTitle: ticket.event.title,
      attendeeName: attendeeName,
      checkedInAt: ticket.checkedInAt,
    );
  }

  /// Maps a recorded check-in failure. Returns null for transport/auth errors.
  static CheckInOutcome? fromApiException(
    ApiException error, {
    required String ticketCode,
    required String method,
  }) {
    final result = errorCodes[error.code];
    if (result == null) return null;
    

    DateTime? checkedInAt;
    final raw = error.fields?['checked_in_at'];
    if (raw is String && raw.isNotEmpty) {
      checkedInAt = DateTime.tryParse(raw)?.toUtc();
    }

    return CheckInOutcome(
      result: result,
      ticketCode: ticketCode,
      method: method,
      message: error.message,
      checkedInAt: checkedInAt,
    );
  }
}
