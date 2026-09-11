import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';

Event _sampleEvent({double priceAmount = 0}) {
  return Event(
    id: 'evt-1',
    title: 'Intro to Flutter Workshop',
    description: 'Hands-on session.',
    startsAt: DateTime.utc(2026, 9, 12, 7),
    locationLabel: 'Building A - Room 304',
    capacity: 50,
    spotsRemaining: 12,
    status: 'published',
    priceAmount: priceAmount,
    priceCurrency: 'USD',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('Price and availability keys exist in English and Khmer', () {
    syncAppTranslations();
    Get.locale = const Locale('en', 'US');
    Get.fallbackLocale = const Locale('en', 'US');

    expect('event_detail_price'.tr, 'Price');
    expect('event_detail_availability'.tr, 'Availability');
    expect('price'.tr, 'Price');
    expect('availability'.tr, 'Availability');

    Get.locale = const Locale('km', 'KH');

    expect('event_detail_price'.tr, 'តម្លៃ');
    expect('event_detail_availability'.tr, 'កន្លែងនៅសល់');
    expect('price'.tr, 'តម្លៃ');
    expect('availability'.tr, 'កន្លែងនៅសល់');
    expect('free'.tr, 'ឥតគិតថ្លៃ');
  });

  testWidgets('Event detail shows Khmer price and availability labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('km', 'KH'),
        fallbackLocale: const Locale('en', 'US'),
        home: EventDetailPage(event: _sampleEvent(priceAmount: 2.5)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('តម្លៃ'), findsOneWidget);
    expect(find.text('កន្លែងនៅសល់'), findsOneWidget);
    expect(find.text('កាលបរិច្ឆេទ'), findsOneWidget);
    expect(find.text('ទីតាំង'), findsOneWidget);
    expect(find.text('Price'), findsNothing);
    expect(find.text('Availability'), findsNothing);
  });
}
