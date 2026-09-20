import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/notifications/notification_controller.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = Get.find<ApiClient>();

    if (!Get.isRegistered<EventController>()) {
      Get.put(EventController(apiClient: apiClient, fetchOnStart: false));
    }
    if (!Get.isRegistered<TicketController>()) {
      Get.put(TicketController(apiClient: apiClient, fetchOnStart: true));
    }
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(
        NotificationController(apiClient: apiClient, fetchOnStart: false),
      );
    }
  }
}
