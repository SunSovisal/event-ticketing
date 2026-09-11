import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/events/attendee.dart';
import 'package:itc_events/modules/admin/events/check_in_attempt.dart';
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

  final RxList<AdminAttendee> attendees = <AdminAttendee>[].obs;
  final RxList<CheckInAttempt> checkInAttempts = <CheckInAttempt>[].obs;
  final RxBool isLoadingDetail = false.obs;
  final RxnString detailErrorMessage = RxnString();
  int _eventsLoadId = 0;
  int _detailLoadId = 0;

  List<Event> get drafts => events.where((event) => event.isDraft).toList();

  List<Event> get published =>
      events.where((event) => event.isPublished).toList();

  List<Event> get cancelled =>
      events.where((event) => event.isCancelled).toList();

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final loadId = ++_eventsLoadId;
    _setRx(loadId, () {
      isLoading.value = true;
      errorMessage.value = null;
    });

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
      errorMessage.value = 'could_not_delete_event'.tr;
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchEventDetail(String eventId) async {
    final loadId = ++_detailLoadId;
    _setRx(loadId, () {
      isLoadingDetail.value = true;
      detailErrorMessage.value = null;
      attendees.clear();
      checkInAttempts.clear();
    }, detail: true);

    try {
      final token = await _token();
      final results = await Future.wait([
        _apiClient.getJson('/admin/events/$eventId/attendees', idToken: token),
        _apiClient.getJson(
          '/admin/events/$eventId/check-in-attempts',
          idToken: token,
        ),
      ]);

      final attendeesData = results[0]['data'];
      final attemptsData = results[1]['data'];
      if (attendeesData is! List || attemptsData is! List) {
        throw ApiException('Unexpected admin event detail response');
      }

      final parsedAttendees = attendeesData
          .whereType<Map<String, dynamic>>()
          .map(AdminAttendee.fromJson)
          .toList();
      final parsedAttempts = attemptsData
          .whereType<Map<String, dynamic>>()
          .map(CheckInAttempt.fromJson)
          .toList();
      _setRx(loadId, () {
        attendees.assignAll(parsedAttendees);
        checkInAttempts.assignAll(parsedAttempts);
      }, detail: true);
    } on ApiException catch (error) {
      _setRx(
        loadId,
        () => detailErrorMessage.value = error.message,
        detail: true,
      );
    } catch (_) {
      _setRx(
        loadId,
        () => detailErrorMessage.value = 'could_not_load_attendees'.tr,
        detail: true,
      );
    } finally {
      _setRx(loadId, () => isLoadingDetail.value = false, detail: true);
    }
  }

  void clearEventDetail() {
    _detailLoadId++;
    _setRx(_detailLoadId, () {
      attendees.clear();
      checkInAttempts.clear();
      detailErrorMessage.value = null;
      isLoadingDetail.value = false;
    }, detail: true);
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
      errorMessage.value = 'could_not_save_event'.tr;
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

  Future<Event?> uploadCover(String eventId, File image) {
    return _mutate((token) {
      return _apiClient.uploadFile(
        '/admin/events/$eventId/cover',
        fieldName: 'image',
        filePath: image.path,
        idToken: token,
      );
    });
  }

  Future<Event?> deleteCover(String eventId) {
    return _mutate((token) {
      return _apiClient.deleteJson(
        '/admin/events/$eventId/cover',
        idToken: token,
      );
    });
  }

  void _setRx(int loadId, void Function() write, {bool detail = false}) {
    void apply() {
      if (detail) {
        if (loadId != _detailLoadId) return;
      } else if (loadId != _eventsLoadId) {
        return;
      }
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
