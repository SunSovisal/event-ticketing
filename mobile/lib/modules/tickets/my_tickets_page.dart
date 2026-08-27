import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
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
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(title: const Text('My tickets')),
      body: Obx(() {
        // me is reactive; isSignedIn covers the brief window before /me returns.
        final signedIn = auth.me.value != null || auth.isSignedIn;
        if (!signedIn) {
          return const EmptyStateView(
            icon: Icons.confirmation_number_outlined,
            message: 'Sign in to see your tickets',
          );
        }

        if (tickets.isLoading.value && tickets.tickets.isEmpty) {
          return const LoadingView(message: 'Loading tickets…');
        }

        if (tickets.errorMessage.value != null && tickets.tickets.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: tickets.errorMessage.value!,
            actionLabel: 'Retry',
            onAction: tickets.fetchTickets,
          );
        }

        final list = switch (_segment) {
          _TicketSegment.upcoming => tickets.upcoming,
          _TicketSegment.past => tickets.past,
          _TicketSegment.cancelled => tickets.cancelled,
        };

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SegmentedButton<_TicketSegment>(
                segments: const [
                  ButtonSegment(
                    value: _TicketSegment.upcoming,
                    label: Text('Upcoming'),
                  ),
                  ButtonSegment(
                    value: _TicketSegment.past,
                    label: Text('Past'),
                  ),
                  ButtonSegment(
                    value: _TicketSegment.cancelled,
                    label: Text('Cancelled'),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (value) {
                  setState(() => _segment = value.first);
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: tickets.fetchTickets,
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.45,
                            child: EmptyStateView(
                              icon: Icons.confirmation_number_outlined,
                              message: switch (_segment) {
                                _TicketSegment.upcoming =>
                                  'No upcoming tickets',
                                _TicketSegment.past => 'No past tickets',
                                _TicketSegment.cancelled =>
                                  'No cancelled tickets',
                              },
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
          _MetaRow(
            icon: Icons.location_on_outlined,
            text: event.locationLabel,
          ),
          const SizedBox(height: 4),
          const _MetaRow(
            icon: Icons.qr_code_2,
            text: 'Tap for QR at entrance',
          ),
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
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
