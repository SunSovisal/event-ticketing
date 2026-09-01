import 'package:flutter/material.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/event_cover_image.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/widgets/event_bookmark_button.dart';

class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showAdminCounts = false,
    this.onBookmark,
    this.isBookmarkBusy = false,
  });

  final Event event;
  final VoidCallback onTap;
  final bool showAdminCounts;
  final VoidCallback? onBookmark;
  final bool isBookmarkBusy;

  Widget? get _statusChip {
    if (showAdminCounts) {
      return StatusChip.eventStatus(event.status);
    }
    if (event.isCancelled) {
      return StatusChip.eventStatus('cancelled');
    }
    if (event.hasEnded()) {
      return const StatusChip(label: 'Ended', color: AppTheme.textSecondary);
    }
    return null;
  }

  String get _spotsLabel {
    if (showAdminCounts) {
      return '${event.reservedCount} reserved · ${event.checkedInCount} checked in';
    }
    if (event.isCancelled) {
      return 'Event cancelled';
    }
    if (event.hasEnded()) {
      return 'Event ended';
    }
    if (event.isSoldOut) {
      return 'Sold out';
    }
    return '${event.spotsRemaining} of ${event.capacity} spots left';
  }

  Color? get _spotsColor {
    if (showAdminCounts) {
      return null;
    }
    if (event.isCancelled || event.isSoldOut) {
      return AppTheme.error;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusChip = _statusChip;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              EventCoverImage(imageUrl: event.imageUrl, borderRadius: 0),
              if (onBookmark != null)
                Positioned(
                  top: 18,
                  right: 18,
                  child: EventBookmarkButton(
                    isSaved: event.isSaved,
                    isBusy: isBookmarkBusy,
                    onDark: true,
                    compact: true,
                    onPressed: onBookmark,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(label: event.category, color: AppTheme.primary),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (statusChip != null) ...[
                      const SizedBox(width: 8),
                      statusChip,
                    ],
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
                _MetaRow(
                  icon: Icons.people_outline,
                  text: _spotsLabel,
                  color: _spotsColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppTheme.textSecondaryOf(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: resolved),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: resolved),
          ),
        ),
      ],
    );
  }
}
