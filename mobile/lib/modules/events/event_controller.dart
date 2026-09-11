import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/saved/saved_event_controller.dart';

class EventController extends GetxController {
  EventController({required ApiClient apiClient, this.fetchOnStart = true})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  final bool fetchOnStart;

  final RxList<Event> events = <Event>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxSet<String> savingIds = <String>{}.obs;
  int _eventsLoadId = 0;

  @override
  void onInit() {
    super.onInit();
    if (fetchOnStart) {
      fetchEvents();
    }
  }

  Event? byId(String id) {
    return events.where((event) => event.id == id).firstOrNull;
  }

  Future<void> fetchEvents() async {
    final loadId = ++_eventsLoadId;
    _setRx(loadId, () {
      isLoading.value = true;
      errorMessage.value = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/events',
        idToken: await _idToken(),
      );
      final data = response['data'];
      if (data is! List) {
        throw ApiException('Unexpected /events response');
      }

      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map(Event.fromJson)
          .toList();
      _setRx(loadId, () => events.assignAll(parsed));
    } on ApiException catch (error) {
      _setRx(loadId, () => errorMessage.value = error.message);
    } catch (_) {
      _setRx(loadId, () => errorMessage.value = 'could_not_load_events'.tr);
    } finally {
      _setRx(loadId, () => isLoading.value = false);
    }
  }

  Future<void> toggleSave(Event event) async {
    final token = await _idToken();
    if (token == null) {
      AppSnackbar.error('sign_in_to_save_events'.tr);
      return;
    }

    final next = !event.isSaved;
    savingIds.add(event.id);
    _setSaved(event, next);

    try {
      if (next) {
        await _apiClient.postJson(
          '/events/${event.id}/save',
          body: const {},
          idToken: token,
        );
      } else {
        await _apiClient.deleteJson('/events/${event.id}/save', idToken: token);
      }
    } on ApiException catch (error) {
      _setSaved(event, !next);
      AppSnackbar.error(error.message);
    } catch (_) {
      _setSaved(event, !next);
      AppSnackbar.error('could_not_update_saved'.tr);
    } finally {
      savingIds.remove(event.id);
    }
  }

  void _setSaved(Event event, bool saved) {
    final updated = event.copyWith(isSaved: saved);
    final index = events.indexWhere((item) => item.id == event.id);
    if (index >= 0) {
      events[index] = events[index].copyWith(isSaved: saved);
    }

    if (Get.isRegistered<SavedEventController>()) {
      Get.find<SavedEventController>().applyToggle(updated, saved);
    }
  }

  Future<String?> _idToken() async {
    if (!Get.isRegistered<AuthController>()) {
      return null;
    }
    return Get.find<AuthController>().getIdToken();
  }

  /// Apply Rx writes after the current frame when a build is in progress so
  /// Home's Obx is not marked dirty while a pushed route (e.g. event detail)
  /// is still mounting.
  void _setRx(int loadId, void Function() write) {
    void apply() {
      if (loadId != _eventsLoadId) return;
      write();
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      apply();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => apply());
  }
}
