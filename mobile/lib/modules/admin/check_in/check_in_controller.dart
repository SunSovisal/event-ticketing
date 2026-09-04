import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/admin/check_in/check_in_outcome.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/tickets/ticket.dart';

class AdminCheckInController extends GetxController {
  AdminCheckInController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<CheckInOutcome> lastResult = Rxn<CheckInOutcome>();

  void clearResult() {
    lastResult.value = null;
    errorMessage.value = null;
  }

  Future<CheckInOutcome?> submit(String ticketCode, {required String method}) async {
    final code = ticketCode.trim();
    if (code.isEmpty) {
      errorMessage.value = 'Please enter a ticket code';
      lastResult.value = null;
      return null;
    }

    isSubmitting.value = true;
    errorMessage.value = null;
    lastResult.value = null;

    try {
      final token = await Get.find<AuthController>().getIdToken();
      if (token == null) {
        throw ApiException('Not signed in', statusCode: 401);
      }

      final response = await _apiClient.postJson(
        '/admin/check-in',
        body: {'ticket_code': code, 'method': method},
        idToken: token,
      );

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Unexpected check-in response');
      }

      final ticket = Ticket.fromJson(data);
      final outcome = CheckInOutcome.fromTicket(
        ticket,
        method: method,
        attendeeName: data['attendee_name'] as String?,
      );
      lastResult.value = outcome;
      return outcome;
    } on ApiException catch (error) {
      final mapped = CheckInOutcome.fromApiException(
        error,
        ticketCode: code,
        method: method,
      );
      if (mapped != null) {
        lastResult.value = mapped;
        return mapped;
      }
      errorMessage.value = error.message;
      return null;
    } catch (_) {
      errorMessage.value = 'Check-in failed.';
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }
}
