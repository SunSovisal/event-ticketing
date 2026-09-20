import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/home_page.dart';
import 'package:itc_events/modules/notifications/models/inbox_notification.dart';
import 'package:itc_events/modules/notifications/notification_controller.dart';
import 'package:itc_events/modules/notifications/notifications_page.dart';

InboxNotification _sampleNotification({
  String id = 'n-1',
  bool isRead = false,
  String body = 'Intro to Flutter Workshop',
}) {
  return InboxNotification(
    id: id,
    type: InboxNotification.typeEventPublished,
    title: 'New event at ITC',
    body: body,
    eventId: 'evt-1',
    isRead: isRead,
    createdAt: DateTime.utc(2026, 9, 13, 8),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('InboxNotification.fromJson maps the inbox payload', () {
    final item = InboxNotification.fromJson({
      'id': 'n-1',
      'type': 'event_published',
      'title': 'New event at ITC',
      'body': 'Campus open day',
      'event_id': 'evt-1',
      'is_read': false,
      'created_at': '2026-09-13T15:00:00+07:00',
      'payload': {'type': 'event_published', 'event_id': 'evt-1'},
    });

    expect(item.id, 'n-1');
    expect(item.type, InboxNotification.typeEventPublished);
    expect(item.title, 'New event at ITC');
    expect(item.body, 'Campus open day');
    expect(item.eventId, 'evt-1');
    expect(item.isRead, isFalse);
    expect(item.opensEvent, isTrue);
    expect(item.createdAt, DateTime.utc(2026, 9, 13, 8));
    expect(item.copyWith(isRead: true).isRead, isTrue);
  });

  testWidgets('EventDate.formatRelative uses inbox copy', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const SizedBox.shrink(),
      ),
    );

    final now = DateTime.utc(2026, 9, 13, 10);
    expect(EventDate.formatRelative(now, now), 'Just now');
    expect(
      EventDate.formatRelative(now.subtract(const Duration(minutes: 3)), now),
      '3 min ago',
    );
    expect(
      EventDate.formatRelative(now.subtract(const Duration(hours: 2)), now),
      '2 hr ago',
    );
    expect(
      EventDate.formatRelative(now.subtract(const Duration(days: 4)), now),
      '4 days ago',
    );
  });

  testWidgets('Home notification icon opens the inbox', (tester) async {
    Get.put(EventController(apiClient: ApiClient(), fetchOnStart: false));
    Get.put(NotificationController(apiClient: ApiClient(), fetchOnStart: false))
      ..hasFetched.value = true;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const HomePage(),
      ),
    );

    expect(find.byKey(const Key('home_header_notifications')), findsOneWidget);
    expect(
      find.byKey(const Key('home_header_notifications_badge')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('home_header_notifications')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('Home notification badge shows unread count', (tester) async {
    Get.put(EventController(apiClient: ApiClient(), fetchOnStart: false));
    Get.put(NotificationController(apiClient: ApiClient(), fetchOnStart: false))
      ..unreadCount.value = 3;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const HomePage(),
      ),
    );

    expect(
      find.byKey(const Key('home_header_notifications_badge')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Notifications page lists stored push messages', (tester) async {
    Get.put(NotificationController(apiClient: ApiClient(), fetchOnStart: false))
      ..hasFetched.value = true
      ..unreadCount.value = 1
      ..items.assignAll([
        _sampleNotification(),
        _sampleNotification(id: 'n-2', isRead: true, body: 'Campus open day'),
      ]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const NotificationsPage(),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('New event at ITC'), findsNWidgets(2));
    expect(find.text('Intro to Flutter Workshop'), findsOneWidget);
    expect(find.text('Campus open day'), findsOneWidget);
    expect(
      find.byKey(const Key('notifications_mark_all_read')),
      findsOneWidget,
    );
  });
}
