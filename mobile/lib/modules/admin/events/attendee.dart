import 'package:itc_events/modules/events/event.dart';

/// Read-only attendee row from `GET /admin/events/{id}/attendees` (§9.3).
class AdminAttendee {
  const AdminAttendee({
    required this.name,
    required this.ticketStatus,
    required this.issuedAt,
    this.studentId,
    this.department,
    this.year,
    this.checkedInAt,
  });

  final String? name;
  final String? studentId;
  final String? department;
  final int? year;
  final String ticketStatus;
  final DateTime issuedAt;
  final DateTime? checkedInAt;

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : 'Unknown';

  String? get campusLine {
    final parts = <String>[
      if (studentId != null && studentId!.isNotEmpty) studentId!,
      if (department != null && department!.isNotEmpty) department!,
      if (year != null) 'Year $year',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  /// UI chip key only — API `ticket_status` is unchanged after check-in closes.
  String displayStatusFor(Event event) {
    if (ticketStatus == 'cancelled' || event.isCancelled) return 'cancelled';
    if (ticketStatus == 'checked_in') return 'checked_in';
    if (event.isCheckInClosed()) return 'ended';
    return 'valid';
  }

  factory AdminAttendee.fromJson(Map<String, dynamic> json) {
    return AdminAttendee(
      name: json['name'] as String?,
      studentId: json['student_id'] as String?,
      department: json['department'] as String?,
      year: _asIntOrNull(json['year']),
      ticketStatus: json['ticket_status'] as String? ?? 'valid',
      issuedAt: DateTime.parse(json['issued_at'] as String).toUtc(),
      checkedInAt: _parseOptionalDate(json['checked_in_at']),
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toUtc();
  }

  static int? _asIntOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
