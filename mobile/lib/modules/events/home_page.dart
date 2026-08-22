import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Event> _filteredEvents(List<Event> events) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return events;

    return events.where((event) {
      return event.title.toLowerCase().contains(q) ||
          event.locationLabel.toLowerCase().contains(q);
    }).toList();
  }

  String _greeting(AuthController? auth) {
    final hour = DateTime.now().hour;
    final time = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final name = auth?.me.value?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return '$time, $name';
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final events = Get.find<EventController>();

    return Obx(() {
      final greeting = _greeting(auth);
      final visible = _filteredEvents(events.events);
      final featured = _query.trim().isEmpty && events.events.isNotEmpty
          ? events.events.first
          : null;

      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(title: const Text('Home')),
        body: RefreshIndicator(
          onRefresh: events.fetchEvents,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Text(greeting, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search events, rooms…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              if (events.isLoading.value && events.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: LoadingView(message: 'Loading events…'),
                )
              else if (events.errorMessage.value != null &&
                  events.events.isEmpty)
                EmptyStateView(
                  icon: Icons.error_outline,
                  message: events.errorMessage.value!,
                  actionLabel: 'Retry',
                  onAction: events.fetchEvents,
                )
              else ...[
                if (featured != null) ...[
                  _FeaturedCard(
                    event: featured,
                    onTap: () =>
                        Get.to(() => EventDetailPage(event: featured)),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Upcoming',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  EmptyStateView(
                    icon: Icons.event_busy,
                    message: _query.trim().isEmpty
                        ? 'No upcoming events yet.'
                        : 'No events match your search.',
                  )
                else
                  ...visible.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EventListCard(
                        event: event,
                        onTap: () =>
                            Get.to(() => EventDetailPage(event: event)),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Featured',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                event.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                EventDate.format(event.startsAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Text('View details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
