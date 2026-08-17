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
    required this.category,
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
  final String category;
  final String? imageUrl;
  final int reservedCount;
  final int checkedInCount;

  bool get isSoldOut => spotsRemaining <= 0;
  bool get isPublished => status == 'published';
  bool get isFree => true;
}
