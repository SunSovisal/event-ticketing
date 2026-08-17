import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';

/// Cover thumbnail or the ITC placeholder strip when [imageUrl] is null.
class EventCoverImage extends StatelessWidget {
  const EventCoverImage({
    super.key,
    this.imageUrl,
    this.height = 140,
    this.borderRadius = 12,
  });

  final String? imageUrl;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imageUrl == null || imageUrl!.isEmpty
            ? const _ItcPlaceholder()
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ItcPlaceholder(),
              ),
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
          children: [
            Image.asset('assets/itc_logo.png', height: 36),
            const SizedBox(width: 10),
            Text(
              'ITC',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
