import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/events/admin_event_controller.dart';

class AdminEventBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdminEventController>()) {
      Get.put(AdminEventController(apiClient: Get.find<ApiClient>()));
    }
  }
}
