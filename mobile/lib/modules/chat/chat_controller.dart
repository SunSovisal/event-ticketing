import 'package:get/get.dart';
import 'package:itc_events/app/locale/locale_controller.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.events = const [],
    this.showActionMenu = false,
  });

  final String role; // user | assistant
  final String content;
  final List<Event> events;
  final bool showActionMenu;

  bool get isUser => role == 'user';
  bool get hasEventCards => events.isNotEmpty;
}

class ChatController extends GetxController {
  ChatController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isSending = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnInt remainingToday = RxnInt();

  @override
  void onInit() {
    super.onInit();
    if (messages.isEmpty) {
      messages.add(_welcomeMessage());
    }
  }

  bool get hasConversation => messages.any((m) => m.isUser);

  ChatMessage _welcomeMessage() {
    return ChatMessage(
      role: 'assistant',
      content: 'chat_menu_prompt'.tr,
      showActionMenu: true,
    );
  }

  void clearChat() {
    messages
      ..clear()
      ..add(_welcomeMessage());
    errorMessage.value = null;
  }

  bool _wantsActionMenu(String text) {
    final lower = text.toLowerCase();
    return RegExp(
      r'\b(hi|hello|hey|help|menu|options|what can you|how can i)\b',
    ).hasMatch(lower);
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || isSending.value) return;

    errorMessage.value = null;
    messages.add(ChatMessage(role: 'user', content: text));
    isSending.value = true;

    try {
      final token = await Get.find<AuthController>().getIdToken();
      if (token == null) {
        throw ApiException('chat_sign_in_required'.tr, statusCode: 401);
      }

      final history = messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .skip(messages.first.isUser ? 0 : 1) // skip welcome
          .toList();
      final prior = history.length > 1
          ? history.sublist(0, history.length - 1)
          : <ChatMessage>[];
      final historyPayload = prior
          .reversed
          .take(4)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final locale = Get.isRegistered<LocaleController>()
          ? Get.find<LocaleController>().languageCode
          : 'en';

      final response = await _apiClient.postJson(
        '/chat',
        body: {
          'message': text,
          'locale': locale,
          'history': historyPayload,
        },
        idToken: token,
      );

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('chat_unexpected'.tr);
      }

      final reply = data['reply']?.toString() ?? '';
      if (reply.isEmpty) {
        throw ApiException('chat_unexpected'.tr);
      }

      final events = _parseEvents(data['events']);

      messages.add(
        ChatMessage(
          role: 'assistant',
          content: reply,
          events: events,
          showActionMenu: events.isEmpty && _wantsActionMenu(text),
        ),
      );

      final meta = response['meta'];
      if (meta is Map && meta['remaining_today'] != null) {
        remainingToday.value = int.tryParse('${meta['remaining_today']}');
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      messages.add(
        ChatMessage(role: 'assistant', content: error.message),
      );
    } catch (_) {
      errorMessage.value = 'chat_unreachable'.tr;
      messages.add(
        ChatMessage(role: 'assistant', content: 'chat_unreachable'.tr),
      );
    } finally {
      isSending.value = false;
    }
  }

  List<Event> _parseEvents(dynamic raw) {
    if (raw is! List) return const [];
    final events = <Event>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        events.add(Event.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Skip malformed event payloads.
      }
    }
    return events;
  }
}
