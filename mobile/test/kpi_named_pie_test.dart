import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/modules/admin/kpis/kpi_charts.dart';
import 'package:itc_events/modules/admin/kpis/kpi_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('department pie shows share labels in the legend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    syncAppTranslations();
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const Scaffold(
          body: KpiNamedPie(
            items: [
              KpiNamedCount(key: 'GIC', count: 14),
              KpiNamedCount(key: 'GEE', count: 6),
            ],
          ),
        ),
      ),
    );

    expect(find.text('GIC 14 (70%)'), findsOneWidget);
    expect(find.text('GEE 6 (30%)'), findsOneWidget);
  });
}
