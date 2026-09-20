import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/kpis/kpi_controller.dart';

class KpiBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<KpiController>()) {
      Get.put(KpiController(apiClient: Get.find<ApiClient>()));
    }
  }
}

class EventKpiBinding extends Bindings {
  EventKpiBinding(this.eventId);

  final String eventId;

  @override
  void dependencies() {
    if (!Get.isRegistered<KpiController>(tag: eventId)) {
      Get.put(
        KpiController(apiClient: Get.find<ApiClient>()),
        tag: eventId,
      );
    }
  }
}
