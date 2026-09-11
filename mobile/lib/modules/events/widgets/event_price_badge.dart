import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/events/event.dart';

/// Free / price pill so a card shows whether checkout is needed.
class EventPriceBadge extends StatelessWidget {
  const EventPriceBadge({super.key, required this.event, this.onImage = false});

  final Event event;

  /// Dark translucent pill for cover photos; solid chip otherwise.
  final bool onImage;

  String get label => event.isFree ? 'free'.tr : event.formattedPrice;

  @override
  Widget build(BuildContext context) {
    final free = event.isFree;
    final Color foreground;
    final Color background;
    final Color border;

    if (onImage) {
      foreground = Colors.white;
      background = Colors.black.withValues(alpha: 0.72);
      border = Colors.white.withValues(alpha: 0.2);
    } else if (free) {
      foreground = AppTheme.success;
      background = AppTheme.success.withValues(alpha: 0.14);
      border = AppTheme.success.withValues(alpha: 0.28);
    } else {
      foreground = Colors.white;
      background = Colors.white.withValues(alpha: 0.18);
      border = Colors.white.withValues(alpha: 0.35);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!free) ...[
              Icon(Icons.payments_outlined, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              key: Key('event_price_${event.id}'),
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
