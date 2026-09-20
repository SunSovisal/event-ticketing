import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/modules/admin/kpis/kpi_charts.dart';
import 'package:itc_events/modules/admin/kpis/models/kpi_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('arrival chart shows peak share and before/after split', (
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
          body: KpiHourChart(
            buckets: [
              KpiHourBucket(label: '-1h', offsetMinutes: -60, count: 2),
              KpiHourBucket(label: 'Start', offsetMinutes: 0, count: 6),
              KpiHourBucket(label: '+30m', offsetMinutes: 30, count: 2),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Peak at Start · 6 (60%)'), findsOneWidget);
    expect(find.text('2 before start · 2 after'), findsOneWidget);
  });
}
