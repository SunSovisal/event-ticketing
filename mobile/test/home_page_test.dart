import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/home_page.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

Event _sampleEvent({
  String? imageUrl,
  String category = 'Workshop',
  double priceAmount = 0,
  String priceCurrency = 'USD',
}) {
  return Event(
    id: 'evt-1',
    title: 'Intro to Flutter Workshop',
    description: 'Hands-on session.',
    startsAt: DateTime.utc(2026, 9, 12, 7),
    locationLabel: 'Building A - Room 304',
    capacity: 50,
    spotsRemaining: 50,
    status: 'published',
    imageUrl: imageUrl,
    category: category,
    priceAmount: priceAmount,
    priceCurrency: priceCurrency,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  EventController controller() {
    return EventController(apiClient: ApiClient(), fetchOnStart: false);
  }

  Future<void> pumpHome(WidgetTester tester, EventController events) async {
    Get.put(events);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const HomePage(),
      ),
    );
  }

  testWidgets('Home shows loading state', (tester) async {
    final events = controller()..isLoading.value = true;
    await pumpHome(tester, events);

    expect(find.text('Loading events…'), findsOneWidget);
  });

  testWidgets('Home shows empty state', (tester) async {
    await pumpHome(tester, controller());

    expect(find.byKey(const Key('home_header_brand')), findsOneWidget);
    expect(find.text('No upcoming events yet.'), findsOneWidget);
  });

  testWidgets('Home header collapses to brand logo only when scrolled', (
    tester,
  ) async {
    final events = controller()
      ..events.assignAll([
        for (var i = 0; i < 8; i++)
          Event(
            id: 'evt-$i',
            title: 'Campus Event $i',
            description: 'Session.',
            startsAt: DateTime.utc(2026, 9, 12 + i, 7),
            locationLabel: 'Building A - Room 30$i',
            capacity: 50,
            spotsRemaining: 50,
            status: 'published',
            category: 'Workshop',
          ),
      ]);
    await pumpHome(tester, events);

    expect(find.byKey(const Key('home_header_brand')), findsOneWidget);
    expect(find.byKey(const Key('home_header_map')), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('home_header_map_opacity')))
          .opacity,
      1,
    );

    await tester.drag(find.text('Upcoming'), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_header_brand')), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('home_header_map_opacity')))
          .opacity,
      0,
    );
  });

  testWidgets('Home shows error state', (tester) async {
    final events = controller()..errorMessage.value = 'Could not load events.';
    await pumpHome(tester, events);

    expect(find.text('Could not load events.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Home shows published events and ITC placeholder', (
    tester,
  ) async {
    final events = controller()..events.assignAll([_sampleEvent()]);
    await pumpHome(tester, events);

    expect(find.text('Intro to Flutter Workshop'), findsWidgets);
    expect(find.text('ITC'), findsOneWidget);
    expect(find.text('50 of 50 spots left'), findsOneWidget);
    expect(find.text('Free'), findsWidgets);
    expect(find.byIcon(Icons.payments_outlined), findsNothing);
    expect(find.byIcon(Icons.bookmark_border), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Workshop'), findsWidgets);
  });

  testWidgets('Home category chip filters the upcoming list', (tester) async {
    final events = controller()
      ..events.assignAll([
        _sampleEvent(),
        Event(
          id: 'evt-2',
          title: 'Open Source Meetup',
          description: 'Lightning talks.',
          startsAt: DateTime.utc(2026, 9, 20, 9),
          locationLabel: 'Building B - Room 204',
          capacity: 60,
          spotsRemaining: 60,
          status: 'published',
          category: 'Meetup',
        ),
      ]);
    await pumpHome(tester, events);

    await tester.tap(find.text('Meetup').first);
    await tester.pumpAndSettle();

    expect(find.text('Open Source Meetup'), findsOneWidget);
    expect(find.text('Intro to Flutter Workshop'), findsNothing);
    expect(find.text('Featured'), findsNothing);
  });

  testWidgets('Home cards show paid price without opening the event', (
    tester,
  ) async {
    final events = controller()
      ..events.assignAll([_sampleEvent(priceAmount: 2.5)]);
    await pumpHome(tester, events);

    expect(find.text(r'$2.50'), findsWidgets);
    expect(find.text('Free'), findsNothing);
    expect(find.byIcon(Icons.payments_outlined), findsWidgets);
  });

  testWidgets('Event detail with live EventController does not throw', (
    tester,
  ) async {
    Get.put(controller()..events.assignAll([_sampleEvent()]));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: EventDetailPage(event: _sampleEvent()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Get ticket'), findsOneWidget);
    expect(find.text('Intro to Flutter Workshop'), findsOneWidget);
  });

  testWidgets('opening event detail from home does not throw', (tester) async {
    final events = controller()..events.assignAll([_sampleEvent()]);
    await pumpHome(tester, events);

    await tester.tap(find.text('Intro to Flutter Workshop').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(find.text('Get ticket'), findsOneWidget);
  });

  testWidgets('Cancelled event card shows Cancelled status', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: EventListCard(
            event: Event(
              id: 'evt-cancelled',
              title: 'Open Source Meetup',
              description: 'Called off.',
              startsAt: DateTime.utc(2026, 8, 26, 14, 11),
              locationLabel: 'Building B - Room 204',
              capacity: 60,
              spotsRemaining: 60,
              status: 'cancelled',
              isSaved: true,
            ),
            onTap: () {},
            onBookmark: () {},
          ),
        ),
      ),
    );

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Event cancelled'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });
}
