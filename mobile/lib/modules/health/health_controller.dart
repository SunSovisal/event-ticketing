import 'package:get/get.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/app/services/api_client.dart';

enum HealthStatus { idle, loading, connected, error }

class HealthController extends GetxController {
  HealthController({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  final Rx<HealthStatus> status = HealthStatus.idle.obs;
  final RxString message = 'tap check to connect to laravel'.obs;

  @override
  void onInit() {
    super.onInit();
    checkHealth();
  }

  // call laravel health endpoint and maps reponse to HealthStatus
  Future<void> checkHealth() async {
    status.value = HealthStatus.loading;
    message.value = 'Connecting to ${AppConfig.apiBaseUrl}...';

    try {
      final response = await _apiClient.getJson('/health');
      final data = response['data'];

      if (data is Map && data['status'] == 'ok') {
        status.value = HealthStatus.connected;
        message.value = 'Backend connected.';
        return;
      }

      status.value = HealthStatus.error;
      message.value = 'Unexpected health response.';
    } on ApiException catch (error) {
      status.value = HealthStatus.error;
      message.value = error.message;
    } catch (_) {
      // Network down, wrong URL, or Laravel not running.
      status.value = HealthStatus.error;
      message.value = 'Could not reach backend. Is Laravel running?';
    }
  }
}
