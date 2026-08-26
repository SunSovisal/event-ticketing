import 'package:itc_events/modules/events/event_category.dart';

/// UI-facing event shape aligned with public/admin event JSON (§8 / §9.3).
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.locationLabel,
    required this.capacity,
    required this.spotsRemaining,
    required this.status,
    this.endsAt,
    this.imageUrl,
    this.reservedCount = 0,
    this.checkedInCount = 0,
    this.isSaved = false,
    this.category = EventCategory.general,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String locationLabel;
  final int capacity;
  final int spotsRemaining;
  final String status;
  final String? imageUrl;
  final int reservedCount;
  final int checkedInCount;
  final bool isSaved;
  final String category;

  bool get isCancelled => status == 'cancelled';
  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isSoldOut => spotsRemaining <= 0;
  bool get isFree => true;

  // missing `ends_at` means the event ends 2 hours after start.
  DateTime get effectiveEndsAt =>
      endsAt ?? startsAt.add(const Duration(hours: 2));

  bool hasEnded([DateTime? at]) {
    final now = (at ?? DateTime.now()).toUtc();
    return !now.isBefore(effectiveEndsAt);
  }
  bool get canEdit => !isCancelled;
  bool get canPublish => isDraft;
  bool get canDelete => isDraft;
  bool get canCancelEvent => isPublished;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAt: _parseOptionalDate(json['ends_at']),
      locationLabel: json['location_label'] as String? ?? '',
      capacity: _asInt(json['capacity']),
      spotsRemaining: _asInt(
        json['spots_remaining'],
        fallback: _asInt(json['capacity']),
      ),
      status: json['status'] as String? ?? 'published',
      imageUrl: _optionalString(json['image_url']),
      reservedCount: _asInt(json['reserved_count']),
      checkedInCount: _asInt(json['checked_in_count']),
      isSaved: json['is_saved'] == true,
      category: json['category'] as String? ?? EventCategory.general,
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    String? locationLabel,
    int? capacity,
    int? spotsRemaining,
    String? status,
    String? imageUrl,
    int? reservedCount,
    int? checkedInCount,
    bool? isSaved,
    String? category,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      locationLabel: locationLabel ?? this.locationLabel,
      capacity: capacity ?? this.capacity,
      spotsRemaining: spotsRemaining ?? this.spotsRemaining,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      reservedCount: reservedCount ?? this.reservedCount,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      isSaved: isSaved ?? this.isSaved,
      category: category ?? this.category,
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toUtc();
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
