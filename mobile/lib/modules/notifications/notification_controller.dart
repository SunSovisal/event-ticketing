import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/services/push_notification_service.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/notifications/models/inbox_notification.dart';

class NotificationController extends GetxController {
  NotificationController({
    required ApiClient apiClient,
    this.fetchOnStart = true,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final bool fetchOnStart;

  final RxList<InboxNotification> items = <InboxNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasFetched = false.obs;
  final RxnString errorMessage = RxnString();

  bool get showInitialLoading =>
      items.isEmpty && (!hasFetched.value || isLoading.value);

  @override
  void onInit() {
    super.onInit();
    if (fetchOnStart) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiClient.getJson(
        '/notifications',
        idToken: await _idToken(),
      );
      final data = response['data'];
      if (data is! List) {
        throw ApiException('Unexpected /notifications response');
      }

      items.assignAll(
        data.whereType<Map<String, dynamic>>().map(InboxNotification.fromJson),
      );
      unreadCount.value =
          _unreadFrom(response['meta']) ??
          items.where((item) => !item.isRead).length;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'could_not_load_notifications'.tr;
    } finally {
      isLoading.value = false;
      hasFetched.value = true;
    }
  }

  Future<void> markRead(String id) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0 || items[index].isRead) {
      return;
    }

    items[index] = items[index].copyWith(isRead: true);
    if (unreadCount.value > 0) {
      unreadCount.value -= 1;
    }

    final token = await _idToken();
    if (token == null) {
      return;
    }

    try {
      final response = await _apiClient.postJson(
        '/notifications/$id/read',
        body: const {},
        idToken: token,
      );
      unreadCount.value = _unreadFrom(response['meta']) ?? unreadCount.value;
    } on ApiException {
      items[index] = items[index].copyWith(isRead: false);
      unreadCount.value += 1;
    } catch (_) {
      items[index] = items[index].copyWith(isRead: false);
      unreadCount.value += 1;
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0 && items.every((item) => item.isRead)) {
      return;
    }

    final previous = items.toList();
    final previousUnread = unreadCount.value;
    items.assignAll(items.map((item) => item.copyWith(isRead: true)));
    unreadCount.value = 0;

    final token = await _idToken();
    if (token == null) {
      return;
    }

    try {
      final response = await _apiClient.postJson(
        '/notifications/read-all',
        body: const {},
        idToken: token,
      );
      final data = response['data'];
      if (data is List) {
        items.assignAll(
          data.whereType<Map<String, dynamic>>().map(
            InboxNotification.fromJson,
          ),
        );
      }
      unreadCount.value = _unreadFrom(response['meta']) ?? 0;
    } on ApiException {
      items.assignAll(previous);
      unreadCount.value = previousUnread;
    } catch (_) {
      items.assignAll(previous);
      unreadCount.value = previousUnread;
    }
  }

  Future<void> markReadForEvent(String eventId) async {
    if (eventId.isEmpty) {
      return;
    }
    if (items.isEmpty && !hasFetched.value) {
      await fetchNotifications();
    }
    final match = items.where((item) => item.eventId == eventId).firstOrNull;
    if (match != null) {
      await markRead(match.id);
    }
  }

  Future<void> markReadById(String notificationId) async {
    if (notificationId.isEmpty) {
      return;
    }
    if (items.isEmpty && !hasFetched.value) {
      await fetchNotifications();
    }
    await markRead(notificationId);
  }

  Future<void> open(InboxNotification item) async {
    await markRead(item.id);
    if (!item.opensEvent) {
      return;
    }
    await PushNotificationService.openEventById(item.eventId!);
  }

  Future<String?> _idToken() async {
    if (!Get.isRegistered<AuthController>()) {
      return null;
    }
    return Get.find<AuthController>().getIdToken();
  }

  int? _unreadFrom(Object? meta) {
    if (meta is! Map) {
      return null;
    }
    final value = meta['unread_count'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
