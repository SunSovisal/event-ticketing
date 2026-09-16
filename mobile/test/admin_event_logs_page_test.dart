import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/events/attendee.dart';
import 'package:itc_events/modules/admin/events/check_in_attempt.dart';
import 'package:itc_events/modules/admin/events/event_controller.dart';
import 'package:itc_events/modules/admin/events/event_detail_page.dart';
import 'package:itc_events/modules/admin/events/event_logs_page.dart';
import 'package:itc_events/modules/events/event.dart';

Event _sampleEvent() {
  return Event(
    id: 'evt-1',
    title: 'Intro to Flutter Workshop',
    description: 'Hands-on session.',
    startsAt: DateTime.utc(2026, 12, 12, 7),
    locationLabel: 'Building A - Room 304',
    capacity: 50,
    spotsRemaining: 48,
    status: 'published',
    reservedCount: 2,
    checkedInCount: 1,
  );
}

AdminAttendee _ticketHolder({
  required String name,
  required String ticketStatus,
}) {
  return AdminAttendee(
    name: name,
    studentId: 'e20240001',
    department: 'GIC',
    year: 3,
    ticketStatus: ticketStatus,
    issuedAt: DateTime.utc(2026, 8, 25, 5),
    checkedInAt: ticketStatus == 'checked_in'
        ? DateTime.utc(2026, 8, 26, 8)
        : null,
  );
}

class _TestAdminEventController extends AdminEventController {
  _TestAdminEventController()
    : super(apiClient: ApiClient(), fetchOnStart: false);

  @override
  Future<void> fetchEventDetail(String eventId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<AdminEventController>(_TestAdminEventController());
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: home,
      ),
    );
  }

  testWidgets('Admin event detail has one manage link to logs', (tester) async {
    await pumpPage(tester, AdminEventDetailPage(event: _sampleEvent()));

    expect(find.text('Intro to Flutter Workshop'), findsOneWidget);
    expect(find.text('2 reserved · 1 checked in'), findsOneWidget);
    expect(find.byKey(const Key('admin_event_manage_nav')), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(
      find.text('Tickets, attendees, and check-in attempts.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('admin_event_tickets_nav')), findsNothing);
    expect(find.byKey(const Key('admin_event_attendees_nav')), findsNothing);
    expect(find.byKey(const Key('admin_event_attempts_nav')), findsNothing);
    expect(find.text('No tickets purchased yet.'), findsNothing);
    expect(find.text('No one has checked in yet.'), findsNothing);
    expect(find.text('No scan attempts yet.'), findsNothing);
  });

  testWidgets('Manage opens event logs with tickets, attendees, and attempts', (
    tester,
  ) async {
    await pumpPage(tester, AdminEventDetailPage(event: _sampleEvent()));

    await tester.tap(find.byKey(const Key('admin_event_manage_nav')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Event logs'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Attendees'), findsOneWidget);
    expect(find.text('Attempts'), findsOneWidget);
    expect(find.text('No tickets purchased yet.'), findsOneWidget);
  });

  testWidgets('Ticket buyers stay off attendees until they check in', (
    tester,
  ) async {
    final controller = _TestAdminEventController()
      ..attendees.assignAll([
        _ticketHolder(name: 'Lin Chea', ticketStatus: 'valid'),
        _ticketHolder(name: 'Dara Sok', ticketStatus: 'checked_in'),
      ])
      ..checkInAttempts.assignAll([
        CheckInAttempt(
          id: 'att-1',
          scannedCode: 'TKT_01TEST',
          attendeeName: 'Dara Sok',
          method: 'qr',
          result: 'success',
          ticketId: 'tkt-1',
          createdAt: DateTime.utc(2026, 8, 26, 9),
        ),
        CheckInAttempt(
          id: 'att-2',
          scannedCode: 'TKT_BAD',
          attendeeName: null,
          method: 'qr',
          result: 'not_found',
          createdAt: DateTime.utc(2026, 8, 26, 9, 1),
        ),
      ]);
    Get.put<AdminEventController>(controller);

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: AdminEventLogsPage(event: _sampleEvent()),
      ),
    );
    await tester.pump();

    expect(find.text('Tickets purchased (2)'), findsOneWidget);
    expect(find.text('Lin Chea'), findsOneWidget);
    expect(find.text('Dara Sok'), findsOneWidget);
    expect(find.text('TKT_01TEST'), findsNothing);

    await tester.tap(find.text('Attendees'));
    await tester.pump();

    expect(find.text('Attendees (1)'), findsOneWidget);
    expect(find.text('Dara Sok'), findsOneWidget);
    expect(find.text('Lin Chea'), findsNothing);
    expect(find.text('TKT_BAD'), findsNothing);

    await tester.tap(find.text('Attempts'));
    await tester.pump();

    expect(find.text('Check-in attempts (2)'), findsOneWidget);
    expect(find.text('TKT_01TEST'), findsOneWidget);
    expect(find.text('TKT_BAD'), findsOneWidget);
    expect(find.text('Lin Chea'), findsNothing);
  });
}
