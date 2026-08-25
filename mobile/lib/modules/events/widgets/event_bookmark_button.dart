import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';

class EventBookmarkButton extends StatelessWidget {
  const EventBookmarkButton({
    super.key,
    required this.isSaved,
    required this.onPressed,
    this.isBusy = false,
    this.onDark = false,
    this.compact = false,
  });

  final bool isSaved;
  final VoidCallback? onPressed;
  final bool isBusy;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = isSaved ? Icons.bookmark : Icons.bookmark_border;
    final color = onDark ? Colors.white : AppTheme.primary;
    final iconSize = compact ? 18.0 : 24.0;
    final spinnerSize = compact ? 14.0 : 18.0;

    final button = IconButton(
      tooltip: isSaved ? 'Remove from saved' : 'Save event',
      onPressed: isBusy ? null : onPressed,
      iconSize: iconSize,
      padding: compact ? const EdgeInsets.all(6) : null,
      constraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      visualDensity: compact ? VisualDensity.compact : null,
      icon: isBusy
          ? SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : Icon(icon, color: color, size: iconSize),
    );

    if (!onDark) {
      return button;
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: button,
    );
  }
}
