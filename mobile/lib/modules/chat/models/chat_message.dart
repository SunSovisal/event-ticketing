import 'package:itc_events/modules/events/models/event.dart';

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.events = const [],
    this.navActions = const [],
    this.showActionMenu = false,
  });

  /// `user` or `assistant`.
  final String role;
  final String content;
  final List<Event> events;
  final List<String> navActions;
  final bool showActionMenu;

  bool get isUser => role == 'user';
  bool get hasEventCards => events.isNotEmpty;
  bool get hasTicketsButton => navActions.contains('tickets');

  ChatMessage copyWith({bool? showActionMenu}) {
    return ChatMessage(
      role: role,
      content: content,
      events: events,
      navActions: navActions,
      showActionMenu: showActionMenu ?? this.showActionMenu,
    );
  }
}
