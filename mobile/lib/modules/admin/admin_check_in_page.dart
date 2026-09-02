import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/admin/admin_event_controller.dart';
import 'package:itc_events/modules/admin/check_in_attempt.dart';

class AdminCheckInPage extends StatefulWidget {
  const AdminCheckInPage({super.key});

  @override
  State<AdminCheckInPage> createState() => _AdminCheckInPageState();
}

class _AdminCheckInPageState extends State<AdminCheckInPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  CheckInAttempt? _checkInResult;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(AdminEventController controller) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _checkInResult = null;
    });

    final result = await controller.submitCheckIn(_codeController.text.trim());

    if (result != null) {
      setState(() {
        _checkInResult = result;
        _codeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminEventController>();

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
                        'Enter the ticket ID or raw QR code value.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _codeController,
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Ticket Code or ID',
                          prefixIcon: const Icon(Icons.confirmation_number_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _codeController.clear(),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a ticket code';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleCheckIn(adminController),
                      ),
                      Obx(() {
                        final error = adminController.errorMessage.value;
                        if (error == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error,
                            style: TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Obx(() {
                        final isSaving = adminController.isSaving.value;
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : () => _handleCheckIn(adminController),
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
                            label: Text(isSaving ? 'Processing...' : 'Submit Check-In'),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            if (_checkInResult != null) ...[
              const SizedBox(height: 20),
              _AttemptResultCard(attempt: _checkInResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttemptResultCard extends StatelessWidget {
  const _AttemptResultCard({required this.attempt});

  final CheckInAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final isSuccess = attempt.result.toLowerCase() == 'success' || 
                      attempt.result.toLowerCase() == 'ok';
    final cardColor = isSuccess ? Colors.green : Colors.orange;

    return Card(
      color: cardColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardColor.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: cardColor.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Result: ${attempt.result.toUpperCase()}',
                  style: TextStyle(
                    color: cardColor.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(label: 'Attendee', value: attempt.displayName),
            const SizedBox(height: 8),
            _DetailRow(label: 'Ticket ID', value: attempt.ticketId ?? attempt.scannedCode),
            const SizedBox(height: 8),
            _DetailRow(label: 'Method', value: attempt.method.toUpperCase()),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}