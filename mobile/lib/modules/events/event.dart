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

  bool get isSoldOut => spotsRemaining <= 0;
  bool get isPublished => status == 'published';
  bool get isFree => true;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAt: _parseOptionalDate(json['ends_at']),
      locationLabel: json['location_label'] as String,
      capacity: _asInt(json['capacity']),
      spotsRemaining: _asInt(
        json['spots_remaining'],
        fallback: _asInt(json['capacity']),
      ),
      status: json['status'] as String? ?? 'published',
      imageUrl: _optionalString(json['image_url']),
      reservedCount: _asInt(json['reserved_count']),
      checkedInCount: _asInt(json['checked_in_count']),
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
