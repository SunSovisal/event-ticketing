import 'package:get/get.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/app/services/api_client.dart';

enum HealthStatus { idle, loading, connected, error }

class HealthController extends GetxController {
  HealthController({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  final Rx<HealthStatus> status = HealthStatus.idle.obs;
  final RxString message = 'health_tap_check'.tr.obs;

  @override
  void onInit() {
    super.onInit();
    checkHealth();
  }

  // call laravel health endpoint and maps reponse to HealthStatus
  Future<void> checkHealth() async {
    status.value = HealthStatus.loading;
    message.value = 'health_connecting'.trParams({'url': AppConfig.apiBaseUrl});

    try {
      final response = await _apiClient.getJson('/health');
      final data = response['data'];

      if (data is Map && data['status'] == 'ok') {
        status.value = HealthStatus.connected;
        message.value = 'health_connected'.tr;
        return;
      }

      status.value = HealthStatus.error;
      message.value = 'health_unexpected'.tr;
    } on ApiException catch (error) {
      status.value = HealthStatus.error;
      message.value = error.message;
    } catch (_) {
      // Network down, wrong URL, or Laravel not running.
      status.value = HealthStatus.error;
      message.value = 'health_unreachable'.tr;
    }
  }
}
