import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/events/saved/bookmark_actions.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/widgets/event_bookmark_button.dart';
import 'package:itc_events/modules/events/widgets/event_category_scroller.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;

  /// 0 = fully expanded, 1 = fully collapsed
  double _headerCollapse = 0;

  static const _collapseRange = 56.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final next = (notification.metrics.pixels / _collapseRange).clamp(0.0, 1.0);
    if ((next - _headerCollapse).abs() > 0.01) {
      setState(() => _headerCollapse = next);
    }
    return false;
  }

  List<Event> _filteredEvents(List<Event> events) {
    var result = events;
    if (_category != null) {
      result = result.where((event) => event.category == _category).toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return result;

    return result.where((event) {
      return event.title.toLowerCase().contains(q) ||
          event.locationLabel.toLowerCase().contains(q) ||
          event.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = Get.find<EventController>();

    return Obx(() {
      final visible = _filteredEvents(events.events);
      final featured =
          _query.trim().isEmpty && _category == null && events.events.isNotEmpty
          ? events.events.first
          : null;

      return Scaffold(
        backgroundColor: AppTheme.scaffoldOf(context),
        body: Column(
          children: [
            _HomeHeader(collapse: _headerCollapse),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: RefreshIndicator(
                  onRefresh: events.fetchEvents,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search events, rooms…',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _query = '';
                              });
                            },
                            icon: Icon(Icons.clear),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      EventCategoryScroller(
                        selected: _category,
                        onSelected: (value) =>
                            setState(() => _category = value),
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
                            onBookmark: () =>
                                toggleEventBookmark(context, featured),
                            isBookmarkBusy: events.savingIds.contains(
                              featured.id,
                            ),
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
                            message: _query.trim().isEmpty && _category == null
                                ? 'No upcoming events yet.'
                                : 'No events match your filters.',
                          )
                        else
                          ...visible.map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: EventListCard(
                                event: event,
                                onTap: () =>
                                    Get.to(() => EventDetailPage(event: event)),
                                onBookmark: () =>
                                    toggleEventBookmark(context, event),
                                isBookmarkBusy: events.savingIds.contains(
                                  event.id,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.collapse});

  /// 0 expanded, 1 collapsed.
  final double collapse;

  static const _expandedBody = 64.0;
  static const _collapsedBody = 52.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final t = Curves.easeOutCubic.transform(collapse);
    final bodyHeight = _expandedBody + (_collapsedBody - _expandedBody) * t;
    final accentOpacity = (1 - t).clamp(0.0, 1.0);
    final scaffold = AppTheme.scaffoldOf(context);
    final highlight = AppTheme.isDark(context)
        ? const Color(0xFF1E3A5F)
        : const Color(0xFFDBEAFE);
    final mid = AppTheme.isDark(context)
        ? AppTheme.surfaceDark
        : const Color(0xFFEFF6FF);
    // final brandLogoHeight = 34.0 - 6.0 * t;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.linear,
      height: topInset + bodyHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(highlight, scaffold, t)!,
            Color.lerp(mid, scaffold, t)!,
            scaffold,
          ],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          if (t > 0.55)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05 * ((t - 0.55) / 0.45)),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: SizedBox(
          height: bodyHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/app_logo_transparent_primary.png',
                      key: const Key('home_header_brand'),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                Opacity(
                  key: const Key('home_header_map_opacity'),
                  opacity: accentOpacity,
                  child: IgnorePointer(
                    ignoring: accentOpacity < 0.05,
                    child: _MapActionButton(onPressed: () {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Map',
      child: Material(
        color: AppTheme.surfaceOf(context),
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: AppTheme.primary.withValues(alpha: 0.2),
        child: InkWell(
          key: const Key('home_header_map'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.map_outlined, color: AppTheme.primary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.event,
    required this.onTap,
    required this.onBookmark,
    required this.isBookmarkBusy,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final bool isBookmarkBusy;

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
              Row(
                children: [
                  Text(
                    'Featured',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·  ${event.category}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const Spacer(),
                  EventBookmarkButton(
                    isSaved: event.isSaved,
                    isBusy: isBookmarkBusy,
                    onDark: true,
                    onPressed: onBookmark,
                  ),
                ],
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
