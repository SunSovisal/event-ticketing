import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/events/event.dart';

class EventController extends GetxController {
  EventController({required ApiClient apiClient, this.fetchOnStart = true})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  final bool fetchOnStart;

  final RxList<Event> events = <Event>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    if (fetchOnStart) {
      fetchEvents();
    }
  }

  Future<void> fetchEvents() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiClient.getJson('/events');
      final data = response['data'];
      if (data is! List) {
        throw ApiException('Unexpected /events response');
      }

      events.assignAll(
        data.whereType<Map<String, dynamic>>().map(Event.fromJson),
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Could not load events.';
    } finally {
      isLoading.value = false;
    }
  }
}
