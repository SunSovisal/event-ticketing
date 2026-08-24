import 'package:itc_events/modules/events/event.dart';

class Ticket {
  final String id;
  final String status;
  final Event event;

  Ticket({
    required this.id,
    required this.status,
    required this.event,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? 'confirmed',
      event: Event.fromJson(
        json['event'] as Map<String, dynamic>,
      ),
    );
  }
}