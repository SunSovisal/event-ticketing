import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/tickets/ticket.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';
import 'package:itc_events/modules/tickets/view_ticket_page.dart';

enum _TicketSegment { upcoming, past, cancelled }

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  _TicketSegment _segment = _TicketSegment.upcoming;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final tickets = Get.find<TicketController>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: 'my_bookings'.tr),
      body: Obx(() {
        // me is reactive; isSignedIn covers the brief window before /me returns.
        final signedIn = auth.me.value != null || auth.isSignedIn;
        if (!signedIn) {
          return EmptyStateView(
            icon: Icons.confirmation_number_outlined,
            message: 'sign_in_to_see_tickets'.tr,
            subtitle: 'tickets_empty_signed_out_subtitle'.tr,
          );
        }

        if (tickets.isLoading.value && tickets.tickets.isEmpty) {
          return LoadingView(message: 'loading_tickets'.tr);
        }

        if (tickets.errorMessage.value != null && tickets.tickets.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: tickets.errorMessage.value!,
            actionLabel: 'refresh'.tr,
            onAction: tickets.fetchTickets,
          );
        }

        final list = switch (_segment) {
          _TicketSegment.upcoming => tickets.upcoming,
          _TicketSegment.past => tickets.past,
          _TicketSegment.cancelled => tickets.cancelled,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TicketStatusTabs(
              selected: _segment,
              onSelected: (value) => setState(() => _segment = value),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: tickets.fetchTickets,
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.55,
                            child: EmptyStateView(
                              icon: Icons.confirmation_number_outlined,
                              message: switch (_segment) {
                                _TicketSegment.upcoming =>
                                  'no_upcoming_tickets'.tr,
                                _TicketSegment.past => 'no_past_tickets'.tr,
                                _TicketSegment.cancelled =>
                                  'no_cancelled_tickets'.tr,
                              },
                              subtitle: switch (_segment) {
                                _TicketSegment.upcoming =>
                                  'no_upcoming_tickets_subtitle'.tr,
                                _TicketSegment.past =>
                                  'no_past_tickets_subtitle'.tr,
                                _TicketSegment.cancelled =>
                                  'no_cancelled_tickets_subtitle'.tr,
                              },
                              actionLabel: 'refresh'.tr,
                              onAction: tickets.fetchTickets,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ticket = list[index];
                          return _TicketCard(
                            ticket: ticket,
                            onTap: () => Get.to(
                              () => ViewTicketPage(ticketId: ticket.id),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TicketStatusTabs extends StatelessWidget {
  const _TicketStatusTabs({required this.selected, required this.onSelected});

  final _TicketSegment selected;
  final ValueChanged<_TicketSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderOf(context)),
        ),
      ),
      child: Row(
        children: [
          for (final segment in _TicketSegment.values)
            Expanded(
              child: _StatusTab(
                label: switch (segment) {
                  _TicketSegment.upcoming => 'segment_upcoming'.tr,
                  _TicketSegment.past => 'segment_past'.tr,
                  _TicketSegment.cancelled => 'segment_cancelled'.tr,
                },
                selected: selected == segment,
                onTap: () => onSelected(segment),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.textSecondaryOf(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 36 : 0,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final event = ticket.event;
    final status = ticket.displayStatus;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip.ticketStatus(status),
            ],
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            text: EventDate.format(event.startsAt),
          ),
          const SizedBox(height: 4),
          _MetaRow(icon: Icons.location_on_outlined, text: event.locationLabel),
          const SizedBox(height: 4),
          _MetaRow(icon: Icons.qr_code_2, text: 'tap_for_qr'.tr),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
