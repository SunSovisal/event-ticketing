import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/mock_events.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Event> _filteredEvents() {
    return MockEvents.published.where((event) {
      final matchesCategory = _category == 'All' || event.category == _category;
      final q = _query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          event.title.toLowerCase().contains(q) ||
          event.locationLabel.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  String _greeting(AuthController auth) {
    final hour = DateTime.now().hour;
    final time = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final name = auth.me.value?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return '$time, $name';
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final greeting = _greeting(auth);
      final featured = MockEvents.featured;
      final events = _filteredEvents();

      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(title: Text('Home')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Text(greeting, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search events, rooms…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (featured != null &&
                _category == 'All' &&
                _query.trim().isEmpty) ...[
              const SizedBox(height: 20),
              _FeaturedCard(
                event: featured,
                onTap: () => Get.to(() => EventDetailPage(event: featured)),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MockEvents.categories.map((category) {
                  final selected = _category == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = category),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.4)
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('This week', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const EmptyStateView(
                icon: Icons.event_busy,
                message: 'No events match your search.',
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WeekEventRow(
                    event: event,
                    onTap: () => Get.to(() => EventDetailPage(event: event)),
                  ),
                ),
              ),
          ],
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

class _WeekEventRow extends StatelessWidget {
  const _WeekEventRow({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      EventDate.format(event.startsAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
