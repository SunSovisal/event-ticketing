import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/event_payment.dart';
import 'package:itc_events/modules/tickets/payment_method.dart';
import 'package:itc_events/modules/tickets/ticket.dart';

class TicketController extends GetxController {
  TicketController({required ApiClient apiClient, this.fetchOnStart = true})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  final bool fetchOnStart;

  final RxList<Ticket> tickets = <Ticket>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isReserving = false.obs;
  final RxBool isPaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (fetchOnStart) {
      fetchTickets();
    }
  }

  Ticket? byId(String id) {
    return tickets.where((ticket) => ticket.id == id).firstOrNull;
  }

  /// One ticket per event per attendee — returns the owned ticket if any.
  Ticket? forEvent(String eventId) {
    return tickets.where((ticket) => ticket.eventId == eventId).firstOrNull;
  }

  List<Ticket> get upcoming =>
      tickets.where((ticket) => ticket.isUpcoming).toList();

  List<Ticket> get past => tickets.where((ticket) => ticket.isPast).toList();

  List<Ticket> get cancelled =>
      tickets.where((ticket) => ticket.isCancelled).toList();

  Future<void> fetchTickets() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token = await _idToken();
      if (token == null) {
        tickets.clear();
        return;
      }

      final response = await _apiClient.getJson('/tickets', idToken: token);
      final data = response['data'];
      if (data is! List) {
        throw ApiException('Unexpected /tickets response');
      }

      tickets.assignAll(
        data
            .whereType<Map<String, dynamic>>()
            .where((item) => item['event'] is Map<String, dynamic>)
            .map(Ticket.fromJson),
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'could_not_load_tickets'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Ticket?> fetchTicket(String id) async {
    try {
      final token = await _idToken();
      if (token == null) {
        throw ApiException('Not signed in', statusCode: 401);
      }

      final response = await _apiClient.getJson('/tickets/$id', idToken: token);
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Unexpected /tickets/$id response');
      }

      final ticket = Ticket.fromJson(data);
      _upsert(ticket);
      return ticket;
    } on ApiException catch (error) {
      AppSnackbar.error(error.message);
      return null;
    } catch (_) {
      AppSnackbar.error('could_not_load_ticket'.tr);
      return null;
    }
  }

  /// Reserves a place for [event]. Returns the ticket (existing or new).
  Future<Ticket?> reserve(Event event) async {
    if (isReserving.value) return null;

    isReserving.value = true;
    try {
      final token = await _idToken();
      if (token == null) {
        AppSnackbar.error('sign_in_to_reserve_ticket'.tr);
        return null;
      }

      final response = await _apiClient.postJson(
        '/events/${event.id}/tickets',
        body: const {},
        idToken: token,
      );
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Unexpected reserve response');
      }

      // Reserve payload may omit nested event fields we already have.
      final merged = Map<String, dynamic>.from(data);
      if (merged['event'] is! Map<String, dynamic>) {
        merged['event'] = {
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'starts_at': event.startsAt.toUtc().toIso8601String(),
          'ends_at': event.endsAt?.toUtc().toIso8601String(),
          'location_label': event.locationLabel,
          'category': event.category,
          'status': event.status,
          'image_url': event.imageUrl,
          'capacity': event.capacity,
          'spots_remaining': event.spotsRemaining,
        };
      }

      final ticket = Ticket.fromJson(merged);
      _upsert(ticket);
      return ticket;
    } on ApiException catch (error) {
      AppSnackbar.error(error.message, title: 'unable_to_get_ticket'.tr);
      return null;
    } catch (_) {
      AppSnackbar.error('could_not_reserve_ticket'.tr, title: 'unable_to_get_ticket'.tr);
      return null;
    } finally {
      isReserving.value = false;
    }
  }

  Future<EventPayment?> startPayment(
    Event event, {
    String method = PaymentMethodOption.khqr,
  }) async {
    if (isPaying.value) return null;

    isPaying.value = true;
    try {
      final token = await _idToken();
      if (token == null) {
        AppSnackbar.error('sign_in_to_reserve_ticket'.tr);
        return null;
      }

      final response = await _apiClient.postJson(
        '/events/${event.id}/payments',
        body: {'method': method},
        idToken: token,
      );
      return _paymentFromResponse(response, event);
    } on ApiException catch (error) {
      if (error.code == 'PAYWAY_DOMAIN') {
        AppSnackbar.error('payway_domain_blocked'.tr, title: 'unable_to_get_ticket'.tr);
        return null;
      }
      AppSnackbar.error(error.message, title: 'unable_to_get_ticket'.tr);
      return null;
    } catch (_) {
      AppSnackbar.error('could_not_start_payment'.tr, title: 'unable_to_get_ticket'.tr);
      return null;
    } finally {
      isPaying.value = false;
    }
  }

  Future<EventPayment?> syncPayment(String paymentId, Event event) async {
    try {
      final token = await _idToken();
      if (token == null) return null;

      final response = await _apiClient.postJson(
        '/payments/$paymentId/sync',
        body: const {},
        idToken: token,
      );
      return _paymentFromResponse(response, event);
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  EventPayment _paymentFromResponse(Map<String, dynamic> response, Event event) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected payment response');
    }

    final merged = Map<String, dynamic>.from(data);
    final ticketJson = merged['ticket'];
    if (ticketJson is Map<String, dynamic> && ticketJson['event'] is! Map<String, dynamic>) {
      merged['ticket'] = {
        ...ticketJson,
        'event': {
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'starts_at': event.startsAt.toUtc().toIso8601String(),
          'ends_at': event.endsAt?.toUtc().toIso8601String(),
          'location_label': event.locationLabel,
          'category': event.category,
          'status': event.status,
          'image_url': event.imageUrl,
          'capacity': event.capacity,
          'spots_remaining': event.spotsRemaining,
          'price_amount': event.priceAmount,
          'price_currency': event.priceCurrency,
        },
      };
    }

    final payment = EventPayment.fromJson(merged);
    final ticket = payment.ticket;
    if (ticket != null) {
      _upsert(ticket);
    }
    return payment;
  }

  void _upsert(Ticket ticket) {
    final index = tickets.indexWhere((item) => item.id == ticket.id);
    if (index >= 0) {
      tickets[index] = ticket;
    } else {
      tickets.insert(0, ticket);
    }
  }

  Future<String?> _idToken() async {
    if (!Get.isRegistered<AuthController>()) {
      return null;
    }
    return Get.find<AuthController>().getIdToken();
  }
}
