import 'package:get/instance_manager.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/chat/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Keep one controller for the app session so reopening chat keeps history.
    if (!Get.isRegistered<ChatController>()) {
      Get.put<ChatController>(
        ChatController(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
    }
  }
}
