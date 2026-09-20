import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/events/models/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/notifications/notification_controller.dart';
import 'package:itc_events/modules/notifications/notifications_page.dart';

const kEventsPublishedTopic = 'events_published';
const kEventsPublishedChannelId = 'events_published';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> register() async {
    try {
      await _register();
    } catch (error, stack) {
      debugPrint('Push registration skipped: $error\n$stack');
    }
  }

  static Future<void> _register() async {
    if (Platform.isIOS) {
      return;
    }

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await messaging.subscribeToTopic(kEventsPublishedTopic);

    // Foreground: FCM does not show a tray banner — post a system notification.
    FirebaseMessaging.onMessage.listen(_onForeground);
    // Background/terminated: OS tray tap opens the app via FCM.
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      await _openFromMessage(initial);
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kEventsPublishedChannelId,
        'New events',
        description: 'Alerts when a new ITC event is published',
        importance: Importance.high,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> _onForeground(RemoteMessage message) async {
    if (!_isEventPublished(message)) {
      return;
    }

    final title = message.notification?.title ?? 'New event at ITC';
    final body = message.notification?.body ?? '';
    final eventId = message.data['event_id']?.toString() ?? '';
    final notificationId = message.data['notification_id']?.toString() ?? '';

    await _refreshInbox();

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          kEventsPublishedChannelId,
          'New events',
          channelDescription: 'Alerts when a new ITC event is published',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      payload: jsonEncode({
        'type': 'event_published',
        'event_id': eventId,
        'notification_id': notificationId,
      }),
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic>) {
        return;
      }
      _openInboxFromPayload(
        eventId: data['event_id']?.toString(),
        notificationId: data['notification_id']?.toString(),
      );
    } catch (error, stack) {
      debugPrint('Local notification tap failed: $error\n$stack');
    }
  }

  static Future<void> _openFromMessage(RemoteMessage message) async {
    await _openInboxFromPayload(
      eventId: message.data['event_id']?.toString(),
      notificationId: message.data['notification_id']?.toString(),
    );
  }

  static Future<void> _openInboxFromPayload({
    String? eventId,
    String? notificationId,
  }) async {
    await _refreshInbox();
    if (Get.isRegistered<NotificationController>()) {
      final inbox = Get.find<NotificationController>();
      if (notificationId != null && notificationId.isNotEmpty) {
        await inbox.markReadById(notificationId);
      } else if (eventId != null && eventId.isNotEmpty) {
        await inbox.markReadForEvent(eventId);
      }
    }
    await _openNotificationsPage();
  }

  static Future<void> _openNotificationsPage() async {
    if (Get.isRegistered<NotificationController>()) {
      await Get.to(() => const NotificationsPage());
    }
  }

  static Future<void> _refreshInbox() async {
    if (Get.isRegistered<NotificationController>()) {
      await Get.find<NotificationController>().fetchNotifications();
    }
  }

  static Future<void> openEventById(String eventId) async {
    if (!Get.isRegistered<ApiClient>()) {
      return;
    }

    try {
      final response = await Get.find<ApiClient>().getJson('/events/$eventId');
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        return;
      }

      final event = Event.fromJson(data);
      if (Get.isRegistered<EventController>()) {
        await Get.find<EventController>().fetchEvents();
      }
      await Get.to(() => EventDetailPage(event: event));
    } on ApiException catch (error) {
      AppSnackbar.error(error.message);
    } catch (_) {
      AppSnackbar.error('could_not_open_event'.tr);
    }
  }

  static bool _isEventPublished(RemoteMessage message) {
    return message.data['type'] == 'event_published';
  }
}
