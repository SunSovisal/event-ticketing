import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/event_cover_image.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/widgets/event_bookmark_button.dart';
import 'package:itc_events/modules/events/widgets/event_price_badge.dart';

class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showAdminCounts = false,
    this.onBookmark,
    this.isBookmarkBusy = false,
    this.compact = false,
  });

  final Event event;
  final VoidCallback onTap;
  final bool showAdminCounts;
  final VoidCallback? onBookmark;
  final bool isBookmarkBusy;

  /// Thumbnail-and-text row used on Home so Upcoming doesn't compete with the
  /// featured hero.
  final bool compact;

  Widget? get _statusChip {
    if (showAdminCounts) {
      return StatusChip.eventStatus(event.status);
    }
    if (event.isCancelled) {
      return StatusChip.eventStatus('cancelled');
    }
    if (event.hasEnded()) {
      return StatusChip(
        label: 'status_ended'.tr,
        color: AppTheme.textSecondary,
      );
    }
    return null;
  }

  String get _spotsLabel {
    if (showAdminCounts) {
      return 'reserved_checked_in'.trParams({
        'reserved': '${event.reservedCount}',
        'checkedIn': '${event.checkedInCount}',
      });
    }
    if (event.isCancelled) {
      return 'event_cancelled'.tr;
    }
    if (event.hasEnded()) {
      return 'event_ended'.tr;
    }
    if (event.isSoldOut) {
      return 'sold_out'.tr;
    }
    return 'spots_left'.trParams({
      'remaining': '${event.spotsRemaining}',
      'capacity': '${event.capacity}',
    });
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
    return compact ? _buildCompact(context) : _buildPoster(context);
  }

  Widget _buildCompact(BuildContext context) {
    final statusChip = _statusChip;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 116,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: 92,
                height: 92,
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.borderOf(context),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        EventCoverImage(
                          imageUrl: event.imageUrl,
                          expand: true,
                          borderRadius: 0,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: EventPriceBadge(event: event, onImage: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(
                          label: event.category,
                          color: AppTheme.primary,
                        ),
                        if (statusChip != null) ...[
                          const SizedBox(width: 6),
                          statusChip,
                        ],
                        const Spacer(),
                        if (onBookmark != null)
                          EventBookmarkButton(
                            isSaved: event.isSaved,
                            isBusy: isBookmarkBusy,
                            compact: true,
                            onPressed: onBookmark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      text: EventDate.format(event.startsAt),
                    ),
                    const SizedBox(height: 2),
                    _MetaRow(
                      icon: Icons.people_outline,
                      text: _spotsLabel,
                      color: _spotsColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final statusChip = _statusChip;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              EventCoverImage(
                imageUrl: event.imageUrl,
                height: 156,
                borderRadius: 0,
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: EventPriceBadge(event: event, onImage: true),
              ),
              if (onBookmark != null)
                Positioned(
                  top: 10,
                  right: 10,
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
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(label: event.category, color: AppTheme.primary),
                    if (statusChip != null) ...[
                      const SizedBox(width: 6),
                      statusChip,
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 14, height: 1.25),
                ),
                const SizedBox(height: 5),
                _MetaLine(
                  date: EventDate.format(event.startsAt),
                  location: event.locationLabel,
                ),
                const SizedBox(height: 2),
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.date, required this.location});

  final String date;
  final String location;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.textSecondaryOf(context);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: color, fontSize: 12);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: style),
        ),
        Icon(Icons.location_on_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
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
        Icon(icon, size: 14, color: resolved),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: resolved, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
