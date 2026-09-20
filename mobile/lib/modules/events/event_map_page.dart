import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/events/models/event.dart';

class EventMapPage extends StatefulWidget {
  const EventMapPage({super.key, this.event});

  final Event? event;

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  static const LatLng _etec = LatLng(11.5621541, 104.8905427);
  static const LatLng _itc = LatLng(11.5703975, 104.8980857);
  static const CameraPosition _campusCamera = CameraPosition(
    target: _itc,
    zoom: 15.2,
  );

  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;
  LatLng? _userPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  String? _distanceText;
  String? _durationText;
  bool _isLoadingRoute = false;
  bool _isLocating = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    _syncMarkers();
    _fitVisiblePoints();
  }

  void _syncMarkers() {
    _markers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('etec'),
          position: _etec,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'etec_name'.tr,
            snippet: 'route_origin'.tr,
          ),
        ),
      )
      ..add(
        Marker(
          markerId: const MarkerId('itc'),
          position: _itc,
          infoWindow: InfoWindow(
            title: 'campus_name'.tr,
            snippet: widget.event?.locationLabel ?? 'campus_address'.tr,
          ),
        ),
      );

    final user = _userPosition;
    if (user != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('you'),
          position: user,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'you_are_here'.tr),
        ),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppSnackbar.warning('location_services_off'.tr);
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      AppSnackbar.warning('location_permission_needed'.tr);
      return false;
    }
    return true;
  }

  Future<void> _locateUser({required bool moveCamera}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      if (!await _ensureLocationPermission()) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;

      _userPosition = LatLng(position.latitude, position.longitude);
      _syncMarkers();

      if (moveCamera) {
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_userPosition!, 16),
        );
      }
    } catch (_) {
      if (moveCamera) {
        AppSnackbar.error('could_not_get_location'.tr);
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _showRoute() async {
    if (_isLoadingRoute) return;
    setState(() => _isLoadingRoute = true);

    try {
      final result = await PolylinePoints.enhanced(AppConfig.googleRoutesApiKey)
          .getRouteBetweenCoordinatesV2(
            request: RoutesApiRequest(
              origin: PointLatLng(_etec.latitude, _etec.longitude),
              destination: PointLatLng(_itc.latitude, _itc.longitude),
              travelMode: TravelMode.driving,
            ),
          );

      final route = result.primaryRoute;
      final points = route?.polylinePoints;
      if (!result.isSuccessful || points == null || points.isEmpty) {
        AppSnackbar.error(result.errorMessage ?? 'could_not_load_route'.tr);
        return;
      }

      if (!mounted) return;
      setState(() {
        _distanceText = route!.distanceKm == null
            ? null
            : '${route.distanceKm!.toStringAsFixed(2)} km';
        _durationText = route.durationMinutes == null
            ? null
            : 'route_minutes'.trParams({
                'minutes': '${route.durationMinutes!.round()}',
              });
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('route_to_campus'),
              points: points
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(),
              color: AppTheme.primary,
              width: 5,
            ),
          );
      });
      _fitVisiblePoints();
    } catch (_) {
      AppSnackbar.error('could_not_load_route'.tr);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _fitVisiblePoints() {
    final points = <LatLng>[_etec, _itc, ?_userPosition];
    if (points.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_campusCamera),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _campusCamera,
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  polylines: _polylines,
                  mapType: _mapType,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  myLocationEnabled: _userPosition != null,
                  myLocationButtonEnabled: false,
                  padding: const EdgeInsets.only(top: 88, bottom: 16),
                ),
                _MapTopBar(onBack: () => Get.back()),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _MapFab(
                        icon: _mapType == MapType.normal
                            ? Icons.layers_outlined
                            : Icons.map_outlined,
                        tooltip: _mapType == MapType.normal
                            ? 'map_type_satellite'.tr
                            : 'map_type_normal'.tr,
                        onPressed: _toggleMapType,
                      ),
                      const SizedBox(height: 10),
                      _MapFab(
                        icon: Icons.my_location,
                        tooltip: 'my_location'.tr,
                        busy: _isLocating,
                        onPressed: () => _locateUser(moveCamera: true),
                      ),
                      const SizedBox(height: 10),
                      _MapFab(
                        icon: Icons.account_balance_outlined,
                        tooltip: 'recenter_campus'.tr,
                        onPressed: _fitVisiblePoints,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CampusSheet(
            highlightedEvent: widget.event,
            isLoadingRoute: _isLoadingRoute,
            distanceText: _distanceText,
            durationText: _durationText,
            onShowRoute: _isLoadingRoute ? null : _showRoute,
          ),
        ],
      ),
    );
  }
}

class _CampusSheet extends StatelessWidget {
  const _CampusSheet({
    required this.highlightedEvent,
    required this.isLoadingRoute,
    required this.distanceText,
    required this.durationText,
    required this.onShowRoute,
  });

  final Event? highlightedEvent;
  final bool isLoadingRoute;
  final String? distanceText;
  final String? durationText;
  final VoidCallback? onShowRoute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceOf(context),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'campus_name'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'campus_address'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (highlightedEvent != null) ...[
                const SizedBox(height: 10),
                Text(
                  highlightedEvent!.locationLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onShowRoute,
                icon: isLoadingRoute
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.directions_outlined),
                label: Text(
                  isLoadingRoute ? 'route_loading'.tr : 'show_route'.tr,
                ),
              ),
              const SizedBox(height: 12),
              _RouteMeta(
                distanceText: distanceText,
                durationText: durationText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          color: AppTheme.surfaceOf(context),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'back'.tr,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'itc_map'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceOf(context),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}

class _RouteMeta extends StatelessWidget {
  const _RouteMeta({required this.distanceText, required this.durationText});

  final String? distanceText;
  final String? durationText;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[?distanceText, ?durationText];
    final label = parts.isEmpty
        ? 'tap_to_route'.tr
        : 'distance_from_you'.trParams({'value': parts.join(' · ')});

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.near_me_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
