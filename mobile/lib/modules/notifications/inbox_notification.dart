class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.eventId,
    this.isRead = false,
    this.data = const {},
  });

  static const typeEventPublished = 'event_published';

  final String id;
  final String type;
  final String title;
  final String body;
  final String? eventId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  bool get opensEvent => eventId != null && eventId!.isNotEmpty;

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: json['id'].toString(),
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventId: _optionalString(json['event_id']),
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      data: _data(json['payload'] ?? json['data']),
    );
  }

  InboxNotification copyWith({bool? isRead}) {
    return InboxNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      eventId: eventId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }

  static Map<String, dynamic> _data(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return value;
  }
}
