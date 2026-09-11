import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/khqr_card.dart';
import 'package:itc_events/modules/tickets/payment_method.dart';
import 'package:itc_events/modules/tickets/payment_method_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formatKhqrAmount uses thousand separators like the KHQR examples', () {
    expect(formatKhqrAmount(1300000, currency: 'KHR'), '1,300,000');
    expect(formatKhqrAmount(2.5, currency: 'USD'), '2.50');
    expect(formatKhqrAmount(10, currency: 'USD'), '10.00');
    expect(formatKhqrAmount(0.01, currency: 'USD'), '0.01');
    expect(formatKhqrAmount(12345.678), '12,345.68');
  });

  testWidgets('KHQR card is 20:29 with left-aligned name and amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 500,
            child: KhqrCard(
              receiverName: 'GoITC',
              amount: 1300000,
              currency: 'KHR',
              qr: '00020101021129370016abaakhppxxx@abaa0109012345678',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('khqr_logo')), findsOneWidget);
    expect(find.text('GoITC'), findsOneWidget);
    expect(find.text('1,300,000'), findsOneWidget);
    expect(find.text('KHR'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/khqr/riel_symbol.png')),
      findsOneWidget,
    );

    final card = tester.getSize(find.byKey(const Key('khqr_card')));
    expect(card.width / card.height, closeTo(KhqrCard.aspectRatio, 0.01));

    final name = tester.getTopLeft(find.text('GoITC'));
    final amount = tester.getTopLeft(find.text('1,300,000'));
    expect((name.dx - amount.dx).abs(), lessThan(1));

    final cardLeft = tester.getTopLeft(find.byKey(const Key('khqr_card'))).dx;
    expect(name.dx - cardLeft, lessThan(card.width / 2));
  });

  testWidgets('USD KHQR card shows 10.00 and a dollar sign on the QR', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 500,
            child: KhqrCard(
              receiverName: 'E-commerce',
              amount: 10,
              currency: 'USD',
              qr: '00020101021129370016abaakhppxxx@abaa0109012345678',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('khqr_logo')), findsOneWidget);
    expect(find.text('10.00'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/khqr/dollar_symbol.png')),
      findsOneWidget,
    );
  });

  testWidgets(
    'payment methods list uses KHQR Payment copy from the guideline',
    (tester) async {
      addTearDown(Get.reset);

      final event = Event(
        id: 'evt-1',
        title: 'Paid workshop',
        description: 'KHQR entry.',
        startsAt: DateTime.utc(2026, 9, 12, 7),
        locationLabel: 'Building A',
        capacity: 40,
        spotsRemaining: 40,
        status: 'published',
        priceAmount: 2.5,
        priceCurrency: 'USD',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: PaymentMethodPage(event: event),
        ),
      );

      expect(find.text('Payment methods'), findsOneWidget);
      expect(find.text('KHQR Payment'), findsOneWidget);
      expect(
        find.text('Scan to pay with Bakong app or any bank apps'),
        findsOneWidget,
      );
      expect(find.text('Choose'), findsNothing);
      expect(find.text('Paid workshop'), findsNothing);
      expect(find.text(r'$2.50'), findsNothing);
    },
  );

  testWidgets('ABA PAY method copy asks to scan the PayWay QR', (tester) async {
    addTearDown(Get.reset);

    final event = Event(
      id: 'evt-1',
      title: 'Paid workshop',
      description: 'ABA PAY entry.',
      startsAt: DateTime.utc(2026, 9, 12, 7),
      locationLabel: 'Building A',
      capacity: 40,
      spotsRemaining: 40,
      status: 'published',
      priceAmount: 2.5,
      priceCurrency: 'USD',
      paymentMethods: const [
        PaymentMethodOption(id: PaymentMethodOption.khqr, live: true),
        PaymentMethodOption(
          id: PaymentMethodOption.abaPay,
          sandbox: true,
        ),
      ],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: PaymentMethodPage(event: event),
      ),
    );

    expect(find.text('ABA PAY'), findsOneWidget);
    expect(find.text('Scan the ABA PAY QR from PayWay'), findsOneWidget);
    expect(find.text('Pay from ABA Mobile'), findsNothing);
  });
}
