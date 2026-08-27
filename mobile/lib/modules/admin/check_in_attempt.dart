/// Row from `GET /admin/events/{id}/check-in-attempts`.
class CheckInAttempt {
  const CheckInAttempt({
    required this.id,
    required this.scannedCode,
    required this.method,
    required this.result,
    required this.createdAt,
    this.attendeeName,
    this.ticketId,
  });

  final String id;
  final String scannedCode;
  final String? attendeeName;
  final String method;
  final String result;
  final String? ticketId;
  final DateTime createdAt;

  String get displayName =>
      (attendeeName != null && attendeeName!.trim().isNotEmpty)
          ? attendeeName!.trim()
          : 'Unknown';

  factory CheckInAttempt.fromJson(Map<String, dynamic> json) {
    return CheckInAttempt(
      id: json['id'].toString(),
      scannedCode: json['scanned_code'] as String? ?? '',
      attendeeName: json['attendee_name'] as String?,
      method: json['method'] as String? ?? 'qr',
      result: json['result'] as String? ?? '',
      ticketId: json['ticket_id']?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }
}
