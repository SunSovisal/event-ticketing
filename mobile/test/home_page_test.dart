import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/home_page.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

Event _sampleEvent({String? imageUrl}) {
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  EventController controller() {
    return EventController(
      apiClient: ApiClient(),
      fetchOnStart: false,
    );
  }

  Future<void> pumpHome(WidgetTester tester, EventController events) async {
    Get.put(events);
    await tester.pumpWidget(GetMaterialApp(home: const HomePage()));
  }

  testWidgets('Home shows loading state', (tester) async {
    final events = controller()..isLoading.value = true;
    await pumpHome(tester, events);

    expect(find.text('Loading events…'), findsOneWidget);
  });

  testWidgets('Home shows empty state', (tester) async {
    await pumpHome(tester, controller());

    expect(find.text('No upcoming events yet.'), findsOneWidget);
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
    expect(find.byIcon(Icons.bookmark_border), findsWidgets);
  });

  testWidgets('Event detail shows bookmark control', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(home: EventDetailPage(event: _sampleEvent())),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('Get ticket'), findsOneWidget);
  });

  testWidgets('Cancelled event card shows Cancelled status', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
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
  });
}
