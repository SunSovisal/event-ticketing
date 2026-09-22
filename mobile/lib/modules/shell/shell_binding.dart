import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/notifications/notification_controller.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = Get.find<ApiClient>();

    // Permanent: Get.offAll('/MainShell') (login/logout) would otherwise
    // delete these with the old route while HomePage is still rebuilding.
    if (!Get.isRegistered<EventController>()) {
      Get.put(
        EventController(apiClient: apiClient, fetchOnStart: false),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TicketController>()) {
      Get.put(
        TicketController(apiClient: apiClient, fetchOnStart: true),
        permanent: true,
      );
    }
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(
        NotificationController(apiClient: apiClient, fetchOnStart: false),
        permanent: true,
      );
    }
  }
}
