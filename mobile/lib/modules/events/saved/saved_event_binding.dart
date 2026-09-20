import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/saved/saved_event_controller.dart';

class SavedEventBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SavedEventController>()) {
      Get.put(SavedEventController(apiClient: Get.find<ApiClient>()));
    }
  }
}
