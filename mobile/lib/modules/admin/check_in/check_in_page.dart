import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/admin/check_in/check_in_controller.dart';
import 'package:itc_events/modules/admin/check_in/widgets/check_in_result_card.dart';

class AdminCheckInPage extends StatefulWidget {
  const AdminCheckInPage({super.key});

  @override
  State<AdminCheckInPage> createState() => _AdminCheckInPageState();
}

class _AdminCheckInPageState extends State<AdminCheckInPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late final AdminCheckInController _checkIn;

  @override
  void initState() {
    super.initState();
    _checkIn = Get.put(
      AdminCheckInController(apiClient: Get.find<ApiClient>()),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    if (Get.isRegistered<AdminCheckInController>()) {
      Get.delete<AdminCheckInController>();
    }
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await _checkIn.submit(
      _codeController.text,
      method: 'manual',
    );
    if (result != null && result.isSuccess) {
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validate Ticket Code',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the ticket QR code.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _codeController,
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Ticket Code',
                          prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _codeController.clear();
                              _checkIn.clearResult();
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a ticket code';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleCheckIn(),
                      ),
                      Obx(() {
                        final error = _checkIn.errorMessage.value;
                        if (error == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Obx(() {
                        final isSaving = _checkIn.isSubmitting.value;
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : _handleCheckIn,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              isSaving ? 'Processing...' : 'Submit Check-In',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() {
              final result = _checkIn.lastResult.value;
              if (result == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: CheckInResultCard(outcome: result),
              );
            }),
          ],
        ),
      ),
    );
  }
}
