import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';

/// Cover thumbnail or the ITC placeholder strip when [imageUrl] is null.
class EventCoverImage extends StatelessWidget {
  const EventCoverImage({
    super.key,
    this.imageUrl,
    this.height = 140,
    this.borderRadius = 12,
    this.expand = false,
    this.fit = BoxFit.cover,
    this.letterboxColor,
  });

  final String? imageUrl;
  final double height;
  final double borderRadius;

  /// When true, fills the parent (e.g. inside [AspectRatio]) instead of a fixed height.
  final bool expand;

  /// [BoxFit.contain] keeps the whole poster visible; unused area uses
  /// [letterboxColor] (white by default).
  final BoxFit fit;
  final Color? letterboxColor;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl == null || imageUrl!.isEmpty
        ? const _ItcPlaceholder()
        : Image.network(
            imageUrl!,
            fit: fit,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => const _ItcPlaceholder(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color:
            letterboxColor ??
            (fit == BoxFit.cover
                ? AppTheme.primary.withValues(alpha: 0.08)
                : Colors.white),
        child: expand
            ? SizedBox.expand(child: image)
            : SizedBox(height: height, width: double.infinity, child: image),
      ),
    );
  }
}

class _ItcPlaceholder extends StatelessWidget {
  const _ItcPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.primary.withValues(alpha: 0.12),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset('assets/itc_logo.png', height: 36)],
        ),
      ),
    );
  }
}
