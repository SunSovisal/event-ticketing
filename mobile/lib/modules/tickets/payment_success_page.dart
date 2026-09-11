import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/shell/main_shell.dart';
import 'package:itc_events/modules/tickets/confirm_tickets_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    super.key,
    required this.event,
    required this.ticketId,
  });

  final Event event;
  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => openMainShell(index: 1),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          event.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textSecondaryOf(context),
                              ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppTheme.success,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'payment_success'.tr,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'payment_success_body'.trParams({
                            'title': event.title,
                          }),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.formattedPrice,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () {
                  Get.offAll(
                    () => ConfirmTicketPage(
                      event: event,
                      ticketId: ticketId,
                    ),
                  );
                },
                child: Text('continue'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
