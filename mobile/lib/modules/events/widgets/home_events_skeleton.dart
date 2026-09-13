import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';

class HomeEventsSkeleton extends StatefulWidget {
  const HomeEventsSkeleton({super.key});

  @override
  State<HomeEventsSkeleton> createState() => _HomeEventsSkeletonState();
}

class _HomeEventsSkeletonState extends State<HomeEventsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final base = AppTheme.isDark(context)
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB);
        final highlight = AppTheme.isDark(context)
            ? const Color(0xFF4B5563)
            : const Color(0xFFF3F4F6);
        final color = Color.lerp(base, highlight, t)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeaturedBone(color: color),
            const SizedBox(height: 20),
            _Bone(color: color, width: 96, height: 18),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _EventCardBone(color: color),
            ],
          ],
        );
      },
    );
  }
}

class _FeaturedBone extends StatelessWidget {
  const _FeaturedBone({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(color: color, width: 72, height: 12),
          const SizedBox(height: 16),
          _Bone(color: color, width: 56, height: 22, radius: 8),
          const SizedBox(height: 12),
          _Bone(color: color, width: 220, height: 22),
          const SizedBox(height: 8),
          _Bone(color: color, width: 140, height: 14),
          const SizedBox(height: 20),
          _Bone(color: color, width: 120, height: 36, radius: 10),
        ],
      ),
    );
  }
}

class _EventCardBone extends StatelessWidget {
  const _EventCardBone({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ColoredBox(
            color: color,
            child: const SizedBox(height: 140, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(color: color, width: 84, height: 22, radius: 11),
                const SizedBox(height: 10),
                _Bone(color: color, width: 200, height: 16),
                const SizedBox(height: 10),
                _Bone(color: color, width: 160, height: 12),
                const SizedBox(height: 6),
                _Bone(color: color, width: 180, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.color,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final Color color;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
