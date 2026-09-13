import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class EventMapPage extends StatelessWidget {
  const EventMapPage({super.key});

  /// Default center location (ITC Phnom Penh)
  static final LatLng _defaultLocation = LatLng(11.570863, 104.897367);
  static final Uri _osmUrl = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );

  Future<void> _openGoogleMaps(BuildContext context, LatLng location) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );

    final opened = await launchUrl(
      googleMapsUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('could_not_open_maps'.tr)));
    }
  }

  Future<void> _openOsm() async {
    await launchUrl(_osmUrl);
  }

  @override
  Widget build(BuildContext context) {
    final eventsController = Get.find<EventController>();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapHeight = (screenHeight * 0.45).clamp(320.0, 420.0);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'event_map'.tr,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final events = eventsController.events;
          final focusEvent = events.isNotEmpty ? events.first : null;
          final mapCenter = _defaultLocation;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                'explore_events_nearby'.tr,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'find_events_desc'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.isDark(context)
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              _MapCard(
                height: mapHeight,
                center: mapCenter,
                events: events,
                onAttributionTap: _openOsm,
              ),
              const SizedBox(height: 16),
              if (focusEvent != null)
                _EventLocationCard(
                  event: focusEvent,
                  onTap: () => Get.to(() => EventDetailPage(event: focusEvent)),
                )
              else
                const _DefaultLocationCard(),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _openGoogleMaps(context, mapCenter),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 20),
                  label: Text('open_in_google_maps'.tr),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.height,
    required this.center,
    required this.events,
    required this.onAttributionTap,
  });

  final double height;
  final LatLng center;
  final List<Event> events;
  final VoidCallback onAttributionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 20,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.itc.itc_events',
                ),
                MarkerLayer(
                  markers: events.map((event) {
                    return Marker(
                      point: EventMapPage._defaultLocation,
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () =>
                            Get.to(() => EventDetailPage(event: event)),
                        child: const _EventMarker(),
                      ),
                    );
                  }).toList(),
                ),
                SimpleAttributionWidget(
                  source: const Text('OpenStreetMap contributors'),
                  onTap: onAttributionTap,
                ),
              ],
            ),
            Positioned(
              top: 14,
              left: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceOf(context),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'itc_events'.tr,
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventMarker extends StatelessWidget {
  const _EventMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.location_on, color: Colors.white, size: 22),
      ),
    );
  }
}

class _EventLocationCard extends StatelessWidget {
  const _EventLocationCard({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.locationLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.isDark(context)
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '11.570863, 104.897367',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.isDark(context)
                    ? Colors.white54
                    : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultLocationCard extends StatelessWidget {
  const _DefaultLocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Institute of Technology of Cambodia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Phnom Penh, Cambodia',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.isDark(context)
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '11.570863, 104.897367',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
