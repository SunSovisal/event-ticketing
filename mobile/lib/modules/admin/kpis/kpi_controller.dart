import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/kpis/kpi_models.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';

class KpiController extends GetxController {
  KpiController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const ranges = ['7d', '30d', '90d', 'all'];

  final range = '30d'.obs;
  final overview = Rxn<KpiOverview>();
  final eventInsights = Rxn<KpiEventInsights>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  int _loadId = 0;

  Future<void> setRange(String next, {String? eventId}) async {
    if (range.value == next) return;
    range.value = next;
    if (eventId != null) {
      await fetchEvent(eventId);
    } else {
      await fetchOverview();
    }
  }

  Future<void> fetchOverview() async {
    final loadId = ++_loadId;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token = await _token();
      final response = await _apiClient.getJson(
        '/admin/kpis?range=${range.value}',
        idToken: token,
      );
      if (loadId != _loadId) return;
      final data = response['data'];
      overview.value = data is Map<String, dynamic>
          ? KpiOverview.fromJson(data)
          : null;
    } on ApiException catch (error) {
      if (loadId != _loadId) return;
      errorMessage.value = error.message;
    } catch (_) {
      if (loadId != _loadId) return;
      errorMessage.value = 'could_not_load_kpis'.tr;
    } finally {
      if (loadId == _loadId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> fetchEvent(String eventId) async {
    final loadId = ++_loadId;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token = await _token();
      final response = await _apiClient.getJson(
        '/admin/events/$eventId/kpis?range=${range.value}',
        idToken: token,
      );
      if (loadId != _loadId) return;
      final data = response['data'];
      eventInsights.value = data is Map<String, dynamic>
          ? KpiEventInsights.fromJson(data)
          : null;
    } on ApiException catch (error) {
      if (loadId != _loadId) return;
      errorMessage.value = error.message;
    } catch (_) {
      if (loadId != _loadId) return;
      errorMessage.value = 'could_not_load_kpis'.tr;
    } finally {
      if (loadId == _loadId) {
        isLoading.value = false;
      }
    }
  }

  Future<String> _token() async {
    final token = await Get.find<AuthController>().getIdToken();
    if (token == null) {
      throw ApiException('Not signed in', statusCode: 401);
    }
    return token;
  }
}
