import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/event_cover_image.dart';
import 'package:itc_events/app/widgets/info_tile.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/sign_in_sheet.dart';
import 'package:itc_events/modules/events/event.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.event});

  final Event event;

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
    final availability = event.isSoldOut
        ? 'Sold out'
        : '${event.spotsRemaining}/${event.capacity}';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                EventCoverImage(
                  imageUrl: event.imageUrl,
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
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.description,
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
                      value: EventDate.formatShort(event.startsAt),
                    ),
                    InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: event.locationLabel,
                    ),
                    InfoTile(
                      icon: Icons.people_outline,
                      label: 'Availability',
                      value: availability,
                      valueColor: event.isSoldOut ? AppTheme.error : null,
                    ),
                    InfoTile(
                      icon: Icons.payments_outlined,
                      label: 'Price',
                      value: event.isFree ? 'Free' : 'Paid',
                    ),
                  ],
                ),
                if (event.isSoldOut) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status: All reserved',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
            onPressed: event.isSoldOut ? null : () => _onGetTicket(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(event.isSoldOut ? 'Event full' : 'Get ticket'),
                if (!event.isSoldOut) ...[
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
