import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';

class SavedEventController extends GetxController {
  SavedEventController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final RxList<Event> events = <Event>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchSaved();
  }

  Event? byId(String id) {
    return events.where((event) => event.id == id).firstOrNull;
  }

  Future<void> fetchSaved() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token = await Get.find<AuthController>().getIdToken();
      if (token == null) {
        throw ApiException('Not signed in', statusCode: 401);
      }

      final response = await _apiClient.getJson(
        '/saved-events',
        idToken: token,
      );
      final data = response['data'];
      if (data is! List) {
        throw ApiException('Unexpected /saved-events response');
      }

      events.assignAll(
        data.whereType<Map<String, dynamic>>().map(Event.fromJson),
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Could not load saved events.';
    } finally {
      isLoading.value = false;
    }
  }

  void applyToggle(Event event, bool saved) {
    if (!saved) {
      events.removeWhere((item) => item.id == event.id);
      return;
    }

    final index = events.indexWhere((item) => item.id == event.id);
    if (index >= 0) {
      events[index] = event.copyWith(isSaved: true);
    } else {
      events.insert(0, event.copyWith(isSaved: true));
    }
  }
}
