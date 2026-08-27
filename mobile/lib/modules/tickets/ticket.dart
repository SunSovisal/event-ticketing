import 'package:itc_events/modules/events/event.dart';

/// Attendee ticket aligned with [TicketResource] (`/tickets`, reserve response).
class Ticket {
  const Ticket({
    required this.id,
    required this.eventId,
    required this.ticketCode,
    required this.status,
    required this.event,
    this.checkedInAt,
    this.createdAt,
  });

  final String id;
  final String eventId;
  final String ticketCode;
  final String status;
  final Event event;
  final DateTime? checkedInAt;
  final DateTime? createdAt;

  bool get isValid => status == 'valid';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCancelled => status == 'cancelled' || event.isCancelled;

  /// upcoming, still usable at the door.
  bool get isUpcoming =>
      !isCancelled && isValid && !event.hasEnded();

  /// past, checked in or event already ended.
  bool get isPast =>
      !isCancelled && (isCheckedIn || event.hasEnded());

  /// status chip, add 'ended' for ui 
  String get displayStatus {
    if (isCancelled) return 'cancelled';
    if (isCheckedIn) return 'checked_in';
    if (event.isCheckInClosed()) return 'ended';
    return 'valid';
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final eventJson = json['event'];
    if (eventJson is! Map<String, dynamic>) {
      throw const FormatException('Ticket JSON missing event');
    }

    return Ticket(
      id: json['id'].toString(),
      eventId: (json['event_id'] ?? eventJson['id']).toString(),
      ticketCode: json['ticket_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'valid',
      checkedInAt: _parseOptionalDate(json['checked_in_at']),
      createdAt: _parseOptionalDate(json['created_at']),
      event: Event.fromJson(eventJson),
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toUtc();
  }
}
