import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/event_cover_image.dart';
import 'package:itc_events/app/widgets/info_tile.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/sign_in_sheet.dart';
import 'package:itc_events/modules/events/bookmark_actions.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/saved_event_controller.dart';
import 'package:itc_events/modules/events/widgets/event_bookmark_button.dart';

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

  Future<void> _onGetTicket(BuildContext context) async {
    final auth = Get.find<AuthController>();

    if (!auth.isSignedIn) {
      final signedIn = await showSignInSheet(context);
      if (!signedIn || !context.mounted) return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reservation will be wired when the tickets API is ready.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EventController>() &&
        !Get.isRegistered<SavedEventController>()) {
      return _buildScaffold(context, event, isBusy: false);
    }

    return Obx(
      () => _buildScaffold(context, _liveEvent(), isBusy: _isBusy()),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    Event live, {
    required bool isBusy,
  }) {
    final availability = live.isCancelled
        ? 'Cancelled'
        : live.hasEnded()
        ? 'Ended'
        : live.isSoldOut
        ? 'Sold out'
        : '${live.spotsRemaining}/${live.capacity}';
    final canReserve =
        live.isPublished && !live.isSoldOut && !live.hasEnded();
    final ctaLabel = live.isCancelled
        ? 'Event cancelled'
        : live.hasEnded()
        ? 'Event ended'
        : live.isSoldOut
        ? 'Event full'
        : 'Get ticket';
    final statusChip = live.isCancelled
        ? StatusChip.eventStatus('cancelled')
        : live.hasEnded()
        ? const StatusChip(label: 'Ended', color: AppTheme.textSecondary)
        : null;

    return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  EventCoverImage(
                    imageUrl: live.imageUrl,
                    height: 220,
                    borderRadius: 0,
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: 8,
                    child: _CircleIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    right: 8,
                    child: EventBookmarkButton(
                      isSaved: live.isSaved,
                      isBusy: isBusy,
                      onDark: true,
                      onPressed: () => toggleEventBookmark(context, live),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          live.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                  Text(
                    live.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
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
                        valueColor:
                            live.isCancelled || live.isSoldOut
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
                  if (live.isCancelled) ...[
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
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: canReserve ? () => _onGetTicket(context) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ctaLabel),
                  if (canReserve) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
