import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/shell/main_shell.dart';
import 'package:itc_events/modules/tickets/ticket.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ViewTicketPage extends StatefulWidget {
  const ViewTicketPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<ViewTicketPage> createState() => _ViewTicketPageState();
}

class _ViewTicketPageState extends State<ViewTicketPage> {
  Ticket? _ticket;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = Get.find<TicketController>();
    final cached = controller.byId(widget.ticketId);
    if (cached != null && cached.ticketCode.isNotEmpty) {
      setState(() {
        _ticket = cached;
        _loading = false;
      });
    }

    final fresh = await controller.fetchTicket(widget.ticketId);
    if (!mounted) return;

    if (fresh != null) {
      setState(() {
        _ticket = fresh;
        _loading = false;
        _error = null;
      });
      return;
    }

    if (_ticket == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load this ticket.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your ticket')),
      body: _buildBody(context),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton(
            onPressed: () => openMainShell(),
            child: const Text('Back to Events'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _ticket == null) {
      return const LoadingView(message: 'Loading ticket…');
    }

    if (_error != null && _ticket == null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Retry',
        onAction: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _load();
        },
      );
    }

    final ticket = _ticket!;
    final event = ticket.event;
    final status = ticket.displayStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  'Show at entrance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (ticket.ticketCode.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text('Ticket code unavailable'),
                  )
                else
                  QrImageView(
                    data: ticket.ticketCode,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                const SizedBox(height: 16),
                SelectableText(
                  ticket.ticketCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                StatusChip.ticketStatus(status),
                if (ticket.checkedInAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Checked in ${EventDate.format(ticket.checkedInAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _TicketRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: EventDate.format(event.startsAt),
                ),
                const SizedBox(height: 12),
                _TicketRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: event.locationLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
