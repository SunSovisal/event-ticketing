import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/admin/events/attendee.dart';
import 'package:itc_events/modules/admin/events/check_in_attempt.dart';
import 'package:itc_events/modules/admin/events/event_controller.dart';
import 'package:itc_events/modules/admin/events/event_form_page.dart';
import 'package:itc_events/modules/events/event.dart';

class AdminEventDetailPage extends StatefulWidget {
  const AdminEventDetailPage({super.key, required this.event});

  final Event event;

  @override
  State<AdminEventDetailPage> createState() => _AdminEventDetailPageState();
}

class _AdminEventDetailPageState extends State<AdminEventDetailPage> {
  late final AdminEventController _controller;
  late Event _event;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminEventController>();
    _event = widget.event;
    _controller.fetchEventDetail(_event.id);
  }

  @override
  void dispose() {
    _controller.clearEventDetail();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _controller.fetchEvents();
    final index = _controller.events.indexWhere((item) => item.id == _event.id);
    if (index >= 0) {
      setState(() => _event = _controller.events[index]);
    }
    await _controller.fetchEventDetail(_event.id);
  }

  Future<void> _openEdit() async {
    await Get.to(() => AdminEventFormPage(event: _event));
    if (!mounted) return;
    final index = _controller.events.indexWhere((item) => item.id == _event.id);
    if (index < 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _event = _controller.events[index]);
    await _controller.fetchEventDetail(_event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event detail'),
        actions: [
          TextButton(
            onPressed: _openEdit,
            child: Text(
              _event.canEdit ? 'Edit' : 'View',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoadingDetail.value &&
            _controller.attendees.isEmpty &&
            _controller.checkInAttempts.isEmpty &&
            _controller.detailErrorMessage.value == null) {
          return const LoadingView(message: 'Loading attendees…');
        }

        if (_controller.detailErrorMessage.value != null &&
            _controller.attendees.isEmpty &&
            _controller.checkInAttempts.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.detailErrorMessage.value!,
            actionLabel: 'Retry',
            onAction: _refresh,
          );
        }

        final attendees = _controller.attendees.toList();
        final attempts = _controller.checkInAttempts.toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SummaryCard(event: _event),
              const SizedBox(height: 20),
              Text(
                'Attendees (${attendees.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (attendees.isEmpty)
                const AppCard(
                  child: Text(
                    'No reservations yet.',
                  ),
                )
              else
                ...attendees.map(
                  (attendee) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AttendeeRow(attendee: attendee, event: _event),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Check-in attempts (${attempts.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (attempts.isEmpty)
                const AppCard(
                  child: Text(
                    'No scan attempts yet.',
                  ),
                )
              else
                ...attempts.map(
                  (attempt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AttemptRow(attempt: attempt),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip.eventStatus(event.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            EventDate.format(event.startsAt),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            event.locationLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '${event.reservedCount} reserved · ${event.checkedInCount} checked in',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.attendee, required this.event});

  final AdminAttendee attendee;
  final Event event;

  @override
  Widget build(BuildContext context) {
    final campus = attendee.campusLine;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (campus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    campus,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          StatusChip.ticketStatus(attendee.displayStatusFor(event)),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt});

  final CheckInAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final methodLabel = attempt.method == 'manual' ? 'Manual' : 'QR';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt.scannedCode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.attemptResult(attempt.result),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$methodLabel · ${EventDate.format(attempt.createdAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
