import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/kpis/kpi_controller.dart';
import 'package:itc_events/modules/admin/kpis/kpi_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<ApiClient>(ApiClient());
    Get.put(KpiController(apiClient: Get.find<ApiClient>()));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const KpiDashboardPage(fetchOnStart: false),
      ),
    );
  }

  testWidgets('KPI dashboard shows empty state before data loads', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('No KPI data yet'), findsOneWidget);
    expect(
      find.text('Publish events and issue tickets to see campus stats.'),
      findsOneWidget,
    );
  });
}
