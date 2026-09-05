import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/event_cover_image.dart';
import 'package:itc_events/app/widgets/info_tile.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/sign_in/widgets/sign_in_sheet.dart';
import 'package:itc_events/modules/events/saved/bookmark_actions.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/saved/saved_event_controller.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/tickets/confirm_tickets_page.dart';
import 'package:itc_events/modules/tickets/ticket.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';
import 'package:itc_events/modules/tickets/view_ticket_page.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.event});

  final Event event;

  Event _liveEvent() {
    Event? home;
    Event? saved;
    if (Get.isRegistered<EventController>()) {
      home = Get.find<EventController>().byId(event.id);
    }
    if (Get.isRegistered<SavedEventController>()) {
      saved = Get.find<SavedEventController>().byId(event.id);
    }
    if (saved != null) {
      return saved;
    }
    if (home != null) {
      return home;
    }
    if (Get.isRegistered<SavedEventController>()) {
      return event.copyWith(isSaved: false);
    }
    return event;
  }

  bool _isBusy() {
    if (!Get.isRegistered<EventController>()) {
      return false;
    }
    return Get.find<EventController>().savingIds.contains(event.id);
  }

  Ticket? _ownedTicket() {
    if (!Get.isRegistered<TicketController>()) return null;
    // Touch the list so Obx rebuilds when tickets change after check-in.
    final tickets = Get.find<TicketController>().tickets;
    return tickets.where((t) => t.eventId == event.id).firstOrNull;
  }

  void _openTicket(String ticketId) {
    Get.to(() => ViewTicketPage(ticketId: ticketId));
  }

  Future<void> _onGetTicket(BuildContext context, Event live) async {
    final auth = Get.find<AuthController>();

    if (!auth.isSignedIn) {
      final signedIn = await showSignInSheet(context);
      if (!signedIn || !context.mounted) return;
    }

    if (!context.mounted) return;

    if (!Get.isRegistered<TicketController>()) {
      return;
    }

    final controller = Get.find<TicketController>();

    // One ticket per event — never show a fresh "You're in!" for an existing one.
    final existing = controller.forEvent(live.id);
    if (existing != null) {
      _openTicket(existing.id);
      return;
    }

    final ticket = await controller.reserve(live);
    if (ticket == null || !context.mounted) return;

    // Server returned the same row (e.g. already checked in) — do not celebrate.
    if (ticket.isCheckedIn) {
      AppSnackbar.warning(
        'You already checked in for this event.',
        title: 'Already checked in',
      );
      _openTicket(ticket.id);
      return;
    }
    if (ticket.isCancelled) {
      AppSnackbar.warning('Your ticket for this event was cancelled.');
      _openTicket(ticket.id);
      return;
    }

    Get.to(() => ConfirmTicketPage(event: live, ticketId: ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EventController>() &&
        !Get.isRegistered<SavedEventController>() &&
        !Get.isRegistered<TicketController>()) {
      return _buildScaffold(
        context,
        event,
        isBusy: false,
        isReserving: false,
        ownedTicket: null,
      );
    }

    return Obx(() {
      final reserving =
          Get.isRegistered<TicketController>() &&
          Get.find<TicketController>().isReserving.value;
      return _buildScaffold(
        context,
        _liveEvent(),
        isBusy: _isBusy(),
        isReserving: reserving,
        ownedTicket: _ownedTicket(),
      );
    });
  }

  Widget _buildScaffold(
    BuildContext context,
    Event live, {
    required bool isBusy,
    required bool isReserving,
    required Ticket? ownedTicket,
  }) {
    final availability = live.isCancelled
        ? 'Cancelled'
        : live.hasEnded()
        ? 'Ended'
        : live.isSoldOut
        ? 'Sold out'
        : '${live.spotsRemaining}/${live.capacity}';
    final hasTicket = ownedTicket != null;
    final canReserve =
        !hasTicket &&
        live.isPublished &&
        !live.isSoldOut &&
        !live.hasEnded() &&
        !isReserving;
    final canViewTicket = hasTicket;
    final ctaLabel = live.isCancelled && !hasTicket
        ? 'Event cancelled'
        : live.hasEnded() && !hasTicket
        ? 'Event ended'
        : live.isSoldOut && !hasTicket
        ? 'Event full'
        : hasTicket
        ? (ownedTicket.isCheckedIn ? 'View checked-in ticket' : 'View ticket')
        : isReserving
        ? 'Reserving…'
        : 'Get ticket';
    final statusChip = live.isCancelled
        ? StatusChip.eventStatus('cancelled')
        : live.hasEnded()
        ? const StatusChip(label: 'Ended', color: AppTheme.textSecondary)
        : null;

    return Scaffold(
      // backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          IconButton(
            tooltip: live.isSaved ? 'Remove from saved' : 'Save event',
            onPressed: isBusy ? null : () => toggleEventBookmark(context, live),
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(live.isSaved ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: EventCoverImage(
              imageUrl: live.imageUrl,
              borderRadius: 16,
              expand: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  live.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (statusChip != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: statusChip,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          StatusChip(label: live.category, color: AppTheme.primary),
          const SizedBox(height: 10),
          Text(live.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              InfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: EventDate.formatShort(live.startsAt),
              ),
              InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: live.locationLabel,
              ),
              InfoTile(
                icon: Icons.people_outline,
                label: 'Availability',
                value: availability,
                valueColor: live.isCancelled || live.isSoldOut
                    ? AppTheme.error
                    : null,
              ),
              InfoTile(
                icon: Icons.payments_outlined,
                label: 'Price',
                value: live.isFree ? 'Free' : 'Paid',
              ),
            ],
          ),
          if (ownedTicket != null) ...[
            const SizedBox(height: 16),
            _StatusBanner(
              message: ownedTicket.isCheckedIn
                  ? 'You already checked in for this event.'
                  : ownedTicket.isCancelled
                  ? 'Your ticket for this event was cancelled.'
                  : 'You already have a ticket for this event.',
              color: ownedTicket.isCheckedIn
                  ? AppTheme.primary
                  : ownedTicket.isCancelled
                  ? AppTheme.error
                  : AppTheme.success,
            ),
          ] else if (live.isCancelled) ...[
            const SizedBox(height: 16),
            _StatusBanner(
              message: 'This event has been cancelled.',
              color: AppTheme.error,
            ),
          ] else if (live.hasEnded()) ...[
            const SizedBox(height: 16),
            _StatusBanner(
              message: 'This event has ended.',
              color: AppTheme.textSecondary,
            ),
          ] else if (live.isSoldOut) ...[
            const SizedBox(height: 16),
            _StatusBanner(
              message: 'Status: All reserved',
              color: AppTheme.error,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: canViewTicket
                ? () => _openTicket(ownedTicket.id)
                : canReserve
                ? () => _onGetTicket(context, live)
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isReserving) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(ctaLabel),
                if ((canReserve || canViewTicket) && !isReserving) ...[
                  const SizedBox(width: 8),
                  Icon(
                    canViewTicket ? Icons.qr_code_2 : Icons.arrow_forward,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
