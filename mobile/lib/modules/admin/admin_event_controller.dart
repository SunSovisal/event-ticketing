import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';

class AdminEventController extends GetxController {
  AdminEventController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final RxList<Event> events = <Event>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token = await Get.find<AuthController>().getIdToken();
      if (token == null) {
        throw ApiException('Not signed in', statusCode: 401);
      }

      final response = await _apiClient.getJson(
        '/admin/events',
        idToken: token,
      );
      final data = response['data'];
      if (data is! List) {
        throw ApiException('Unexpected /admin/events response');
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

  Future<Event?> createEvent(Map<String, dynamic> body) {
    return _mutate((token) {
      return _apiClient.postJson('/admin/events', body: body, idToken: token);
    });
  }

  Future<Event?> updateEvent(String id, Map<String, dynamic> body) {
    return _mutate((token) {
      return _apiClient.patchJson(
        '/admin/events/$id',
        body: body,
        idToken: token,
      );
    });
  }

  Future<Event?> publishEvent(String id) {
    return _mutate((token) {
      return _apiClient.postJson(
        'admin/events/$id/publish',
        body: const {},
        idToken: token,
      );
    });
  }

  Future<Event?> cancelEvent(String id) {
    return _mutate((token) {
      return _apiClient.postJson(
        'admin/events/$id/cancel',
        body: const {},
        idToken: token,
      );
    });
  }

  Future<bool> deleteDraft(String id) async {
    isSaving.value = true;
    errorMessage.value = null;

    try {
      final token = await _token();
      await _apiClient.deleteJson('/admin/events/$id', idToken: token);
      events.removeWhere((item) => item.id == id);
      _refreshHome();
      return true;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      return false;
    } catch (_) {
      errorMessage.value = 'Could not delete event.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<Event?> _mutate(
    Future<Map<String, dynamic>> Function(String token) request,
  ) async {
    isSaving.value = true;
    errorMessage.value = null;
    try {
      final token = await _token();
      final response = await request(token);
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Unexpected admin event response');
      }
      final event = Event.fromJson(data);
      _upsert(event);
      _refreshHome();
      return event;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      return null;
    } catch (_) {
      errorMessage.value = 'Could not save event.';
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  void _upsert(Event event) {
    final index = events.indexWhere((item) => item.id == event.id);
    if (index >= 0) {
      events[index] = event;
    } else {
      events.add(event);
    }
  }

  void _refreshHome() {
    if (Get.isRegistered<EventController>()) {
      Get.find<EventController>().fetchEvents();
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
