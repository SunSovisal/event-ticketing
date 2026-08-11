import 'package:get/instance_manager.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/health/health_controller.dart';

class HealthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HealthController>(
      () => HealthController(apiClient: Get.find<ApiClient>()),
    );
  }
}
