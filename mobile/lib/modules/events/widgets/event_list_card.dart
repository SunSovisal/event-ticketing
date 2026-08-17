import 'package:flutter/material.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/event_cover_image.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/events/event.dart';

class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showAdminCounts = false,
  });

  final Event event;
  final VoidCallback onTap;
  final bool showAdminCounts;

  @override
  Widget build(BuildContext context) {
    final spotsLabel = event.isSoldOut
        ? 'Sold out'
        : '${event.spotsRemaining} of ${event.capacity} spots left';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventCoverImage(imageUrl: event.imageUrl, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    if (showAdminCounts) ...[
                      const SizedBox(width: 8),
                      StatusChip.eventStatus(event.status),
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
                  text: showAdminCounts
                      ? '${event.reservedCount} reserved · ${event.checkedInCount} checked in'
                      : spotsLabel,
                  color: !showAdminCounts && event.isSoldOut
                      ? AppTheme.error
                      : null,
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
    final resolved = color ?? AppTheme.textSecondary;
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
