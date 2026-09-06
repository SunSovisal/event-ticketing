import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/shell/main_shell.dart';
import 'package:itc_events/modules/tickets/view_ticket_page.dart';

class ConfirmTicketPage extends StatelessWidget {
  const ConfirmTicketPage({
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => openMainShell(index: 1),
                ),
              ),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'youre_in'.tr,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(text: 'ticket_ready_prefix'.tr),
                    TextSpan(
                      text: event.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    TextSpan(
                      text: 'ticket_ready_suffix'.tr,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Column(
                  children: [
                    Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      EventDate.format(event.startsAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.locationLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Get.off(
                    () => ViewTicketPage(ticketId: ticketId),
                  );
                },
                child: Text('view_my_ticket'.tr),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => openMainShell(index: 1),
                child: Text('go_to_my_tickets'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
