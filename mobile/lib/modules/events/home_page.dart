import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/modules/events/event_map_page.dart';
import 'package:itc_events/modules/events/saved/bookmark_actions.dart';
import 'package:itc_events/modules/events/models/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/widgets/event_bookmark_button.dart';
import 'package:itc_events/modules/events/widgets/event_category_scroller.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';
import 'package:itc_events/modules/events/widgets/event_price_badge.dart';
import 'package:itc_events/modules/events/widgets/home_events_skeleton.dart';
import 'package:itc_events/modules/notifications/notification_controller.dart';
import 'package:itc_events/modules/notifications/notifications_page.dart';

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
  static const _featuredCount = 3;

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

  /// Top events for the hero carousel. Hidden while searching or filtering so
  /// the results are the only thing on screen.
  List<Event> _featuredEvents(List<Event> events) {
    if (_query.trim().isNotEmpty || _category != null) return const [];
    return events.take(_featuredCount).toList();
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
      final featured = _featuredEvents(events.events);
      final featuredIds = featured.map((event) => event.id).toSet();

      // Featured events are not repeated in the list below.
      final visible = _filteredEvents(
        events.events,
      ).where((event) => !featuredIds.contains(event.id)).toList();

      // With few events the carousel can consume all of them; showing an
      // "upcoming" empty state under a full carousel would read as a bug.
      final showUpcoming = visible.isNotEmpty || featured.isEmpty;
      final busyIds = events.savingIds.toSet();

      final unread = Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>().unreadCount.value
          : 0;

      return Scaffold(
        backgroundColor: AppTheme.scaffoldOf(context),
        body: Column(
          children: [
            _HomeHeader(collapse: _headerCollapse, unreadCount: unread),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await events.fetchEvents();
                    if (Get.isRegistered<NotificationController>()) {
                      await Get.find<NotificationController>()
                          .fetchNotifications();
                    }
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'search_events_hint'.tr,
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
                      if (events.showInitialLoading)
                        const HomeEventsSkeleton(
                          key: Key('home_events_skeleton'),
                        )
                      else if (events.errorMessage.value != null &&
                          events.events.isEmpty)
                        EmptyStateView(
                          icon: Icons.error_outline,
                          message: events.errorMessage.value!,
                          actionLabel: 'retry'.tr,
                          onAction: events.fetchEvents,
                        )
                      else ...[
                        if (featured.isNotEmpty) ...[
                          _FeaturedCarousel(
                            key: const Key('home_featured_carousel'),
                            events: featured,
                            busyIds: busyIds,
                            onOpen: (event) =>
                                Get.to(() => EventDetailPage(event: event)),
                            onBookmark: (event) =>
                                toggleEventBookmark(context, event),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (showUpcoming) ...[
                          Text(
                            'upcoming'.tr,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          if (visible.isEmpty)
                            EmptyStateView(
                              icon: Icons.event_busy,
                              message:
                                  _query.trim().isEmpty && _category == null
                                  ? 'no_upcoming_events'.tr
                                  : 'no_events_match_filters'.tr,
                            )
                          else
                            ...visible.map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: EventListCard(
                                  event: event,
                                  compact: true,
                                  onTap: () => Get.to(
                                    () => EventDetailPage(event: event),
                                  ),
                                  onBookmark: () =>
                                      toggleEventBookmark(context, event),
                                  isBookmarkBusy: busyIds.contains(event.id),
                                ),
                              ),
                            ),
                        ],
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
  const _HomeHeader({required this.collapse, required this.unreadCount});

  /// 0 expanded, 1 collapsed.
  final double collapse;
  final int unreadCount;

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
                    child: Row(
                      children: [
                        _HeaderActionButton(
                          buttonKey: const Key('home_header_notifications'),
                          tooltip: 'notifications'.tr,
                          icon: Icons.notifications_outlined,
                          badgeCount: unreadCount,
                          onPressed: _openNotifications,
                        ),
                        const SizedBox(width: 8),
                        _HeaderActionButton(
                          buttonKey: const Key('home_header_map'),
                          tooltip: 'Map',
                          icon: Icons.map_outlined,
                          onPressed: () => Get.to(() => const EventMapPage()),
                        ),
                      ],
                    ),
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

void _openNotifications() {
  Get.to(() => const NotificationsPage());
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          key: buttonKey,
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppTheme.primary, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      key: const Key('home_header_notifications_badge'),
                      constraints: const BoxConstraints(minWidth: 14),
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
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

/// Auto-advancing hero carousel for the top events. Swiping wraps around in
/// both directions, so there is no dead end at either edge.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({
    super.key,
    required this.events,
    required this.busyIds,
    required this.onOpen,
    required this.onBookmark,
  });

  final List<Event> events;
  final Set<String> busyIds;
  final ValueChanged<Event> onOpen;
  final ValueChanged<Event> onBookmark;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _autoAdvance = Duration(seconds: 3);
  static const _slide = Duration(milliseconds: 120);

  /// The page list is the events repeated many times to fake an endless strip.
  /// [_onPageChanged] recenters long before either end is reachable.
  static const _loops = 400;

  static const _viewportFraction = 0.94;

  late final PageController _controller = PageController(
    initialPage: _middlePage,
    viewportFraction: _viewportFraction,
  );

  Timer? _timer;
  int _index = 0;

  int get _count => widget.events.length;
  int get _middlePage => _count * (_loops ~/ 2);

  /// Full-width hero, capped so tablets don't get a billboard.
  static double _heightFor(double width) => (width / 1.55).clamp(216.0, 248.0);

  static double _sideInset(double width) => width * (1 - _viewportFraction) / 2;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(_FeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != _count) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(_middlePage);
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_count < 2) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!mounted || !_controller.hasClients) return;

      // Home stays mounted behind a pushed event page; don't advance there.
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      _controller.nextPage(duration: _slide, curve: Curves.easeInOutCubic);
    });
  }

  void _onPageChanged(int page) {
    setState(() => _index = page % _count);

    if (page < _count || page > _count * (_loops - 1)) {
      // Recenter once the slide has settled so the jump is never visible.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(_middlePage + _index);
        }
      });
    }
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    final current = _controller.page?.round() ?? _middlePage;
    _controller.animateToPage(
      current + (index - _index),
      duration: _slide,
      curve: Curves.easeInOutCubic,
    );
    _restartTimer();
  }

  Widget _cardFor(Event event) {
    return _FeaturedCard(
      event: event,
      onTap: () => widget.onOpen(event),
      onBookmark: () => widget.onBookmark(event),
      isBookmarkBusy: widget.busyIds.contains(event.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _heightFor(constraints.maxWidth);

        if (_count < 2) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _sideInset(constraints.maxWidth),
            ),
            child: SizedBox(
              height: height,
              child: _cardFor(widget.events.first),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: height,
              child: Listener(
                // Auto-advance should never fight the user's thumb.
                onPointerDown: (_) => _timer?.cancel(),
                onPointerUp: (_) => _restartTimer(),
                onPointerCancel: (_) => _restartTimer(),
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: _onPageChanged,
                  itemCount: _count * _loops,
                  itemBuilder: (context, page) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _cardFor(widget.events[page % _count]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CarouselDots(count: _count, index: _index, onTap: _goTo),
          ],
        );
      },
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({
    required this.count,
    required this.index,
    required this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: i == index ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(
                    alpha: i == index ? 1 : 0.25,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hero card for a featured event: cover photo under a scrim, or a branded
/// gradient backdrop when the event has no cover. Tapping anywhere opens the
/// event, so there is no separate action button.
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

  static const _radius = 22.0;

  bool get _hasPhoto => event.imageUrl != null && event.imageUrl!.isNotEmpty;

  Widget? get _statusChip {
    if (event.isCancelled) {
      return _HeroChip(label: 'status_cancelled'.tr, color: AppTheme.error);
    }
    if (event.hasEnded()) {
      return _HeroChip(label: 'status_ended'.tr, color: AppTheme.textSecondary);
    }
    if (event.isSoldOut) {
      return _HeroChip(label: 'sold_out'.tr, color: AppTheme.warning);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusChip = _statusChip;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('home_featured_card_${event.id}'),
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasPhoto)
              Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _FeaturedBackdrop(),
              )
            else
              const _FeaturedBackdrop(),

            // Photos need a heavy scrim plus a brand tint to keep white
            // text readable and match the rest of the app. The gradient
            // backdrop is already dark by design, so it only gets a
            // light lift under the text.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _hasPhoto
                        ? [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.65),
                          ]
                        : [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.45),
                          ],
                    stops: const [0, 0.3, 0.62, 1],
                  ),
                ),
                child: _hasPhoto
                    ? ColoredBox(
                        color: AppTheme.heroBlue.withValues(alpha: 0.2),
                      )
                    : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _FeaturedPill(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const Spacer(),
                  EventPriceBadge(event: event, onImage: true),
                  if (statusChip != null) ...[
                    const SizedBox(height: 8),
                    statusChip,
                  ],
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HeroMetaRow(
                    icon: Icons.calendar_today_outlined,
                    text: EventDate.format(event.startsAt),
                    emphasized: true,
                  ),
                  const SizedBox(height: 4),
                  _HeroMetaRow(
                    icon: Icons.location_on_outlined,
                    text: event.locationLabel,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
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
      ),
    );
  }
}

/// Branded backdrop used when an event has no cover photo, so the fallback
/// reads as a deliberate design rather than a missing image.
class _FeaturedBackdrop extends StatelessWidget {
  const _FeaturedBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.heroIndigo, AppTheme.primary, AppTheme.heroBlue],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(1.15, -1.25),
            child: _Glow(size: 200, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Align(
            alignment: const Alignment(-1.2, 1.35),
            child: _Glow(
              size: 180,
              color: AppTheme.heroIndigo.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            right: -16,
            bottom: -12,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/itc_logo.png', height: 130),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _FeaturedPill extends StatelessWidget {
  const _FeaturedPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'featured'.tr,
              style: TextStyle(
                color: Colors.white,
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

/// Status pill with enough contrast to sit on a cover photo.
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
          ),
        ),
      ),
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: emphasized ? 0.95 : 0.75);
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
