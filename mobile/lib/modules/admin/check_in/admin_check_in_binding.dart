import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/check_in/admin_check_in_controller.dart';

class AdminCheckInBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdminCheckInController>()) {
      Get.put(AdminCheckInController(apiClient: Get.find<ApiClient>()));
    }
  }
}
