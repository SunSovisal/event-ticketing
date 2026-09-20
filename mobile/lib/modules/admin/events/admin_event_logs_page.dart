import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/admin/events/models/admin_attendee.dart';
import 'package:itc_events/modules/admin/events/models/check_in_attempt.dart';
import 'package:itc_events/modules/admin/events/admin_event_controller.dart';
import 'package:itc_events/modules/events/models/event.dart';

enum EventLogSegment { tickets, attendees, attempts }

class AdminEventLogsPage extends StatefulWidget {
  const AdminEventLogsPage({
    super.key,
    required this.event,
    this.initialSegment = EventLogSegment.tickets,
  });

  final Event event;
  final EventLogSegment initialSegment;

  @override
  State<AdminEventLogsPage> createState() => _AdminEventLogsPageState();
}

class _AdminEventLogsPageState extends State<AdminEventLogsPage> {
  late final AdminEventController _controller;
  late EventLogSegment _segment;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminEventController>();
    _segment = widget.initialSegment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.fetchEventDetail(widget.event.id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<AdminEventController>()) return;
      final current = Get.find<AdminEventController>();
      if (identical(current, _controller)) {
        current.clearEventDetail();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: 'event_logs'.tr),
      body: Obx(() {
        if (_controller.isLoadingDetail.value &&
            _controller.attendees.isEmpty &&
            _controller.checkInAttempts.isEmpty &&
            _controller.detailErrorMessage.value == null) {
          return LoadingView(message: 'loading_event_logs'.tr);
        }

        if (_controller.detailErrorMessage.value != null &&
            _controller.attendees.isEmpty &&
            _controller.checkInAttempts.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.detailErrorMessage.value!,
            actionLabel: 'retry'.tr,
            onAction: () => _controller.fetchEventDetail(widget.event.id),
          );
        }

        final tickets = _controller.attendees.toList();
        final attendees = tickets.where((item) => item.isCheckedIn).toList();
        final attempts = _controller.checkInAttempts.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LogTabs(
              selected: _segment,
              onSelected: (value) => setState(() => _segment = value),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _controller.fetchEventDetail(widget.event.id),
                child: switch (_segment) {
                  EventLogSegment.tickets => _PersonList(
                    event: widget.event,
                    people: tickets,
                    countKey: 'tickets_purchased_count',
                    emptyIcon: Icons.confirmation_number_outlined,
                    emptyMessage: 'no_tickets_purchased_yet'.tr,
                  ),
                  EventLogSegment.attendees => _PersonList(
                    event: widget.event,
                    people: attendees,
                    countKey: 'attendees_count',
                    emptyIcon: Icons.people_outline,
                    emptyMessage: 'no_attendees_yet'.tr,
                  ),
                  EventLogSegment.attempts => _AttemptList(attempts: attempts),
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LogTabs extends StatelessWidget {
  const _LogTabs({required this.selected, required this.onSelected});

  final EventLogSegment selected;
  final ValueChanged<EventLogSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderOf(context))),
      ),
      child: Row(
        children: [
          for (final segment in EventLogSegment.values)
            Expanded(
              child: _LogTab(
                label: switch (segment) {
                  EventLogSegment.tickets => 'tab_tickets'.tr,
                  EventLogSegment.attendees => 'tab_attendees'.tr,
                  EventLogSegment.attempts => 'tab_attempts'.tr,
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

class _LogTab extends StatelessWidget {
  const _LogTab({
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

class _PersonList extends StatelessWidget {
  const _PersonList({
    required this.event,
    required this.people,
    required this.countKey,
    required this.emptyIcon,
    required this.emptyMessage,
  });

  final Event event;
  final List<AdminAttendee> people;
  final String countKey;
  final IconData emptyIcon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: EmptyStateView(icon: emptyIcon, message: emptyMessage),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: people.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            countKey.trParams({'count': '${people.length}'}),
            style: Theme.of(context).textTheme.titleMedium,
          );
        }
        return _AttendeeRow(attendee: people[index - 1], event: event);
      },
    );
  }
}

class _AttemptList extends StatelessWidget {
  const _AttemptList({required this.attempts});

  final List<CheckInAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: EmptyStateView(
              icon: Icons.qr_code_scanner_outlined,
              message: 'no_scan_attempts_yet'.tr,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: attempts.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'check_in_attempts_count'.trParams({'count': '${attempts.length}'}),
            style: Theme.of(context).textTheme.titleMedium,
          );
        }
        return _AttemptRow(attempt: attempts[index - 1]);
      },
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
                  Text(campus, style: Theme.of(context).textTheme.bodySmall),
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
    final methodLabel = attempt.method == 'manual' ? 'manual'.tr : 'qr'.tr;

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
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
