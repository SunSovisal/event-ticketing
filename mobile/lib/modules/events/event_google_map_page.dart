import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:itc_events/app/theme/app_theme.dart';

class EventMapPage extends StatefulWidget {
  const EventMapPage({super.key});

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  late GoogleMapController _mapController;

  // Replace with your Google Cloud API Key (Must have Directions API enabled)
  static const String _googleApiKey = "AIzaSyBTzZVtm0j7PyCGPy7xKlHG0R5W_4dHAX0";

  // Fixed coordinates for ETEC and ITC
  static const LatLng _etecPosition = LatLng(
    11.5621541,
    104.8905427,
  ); // ETEC Center
  static const LatLng _itcPosition = LatLng(
    11.5703975,
    104.8980857,
  ); // ITC Campus

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  String? _distanceText;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _setupInitialMarkers();
  }

  void _setupInitialMarkers() {
    _markers.addAll([
      // Origin Marker (ETEC Center)
      const Marker(
        markerId: MarkerId('etec_origin'),
        position: _etecPosition,
        infoWindow: InfoWindow(
          title: 'ETEC Training Center',
          snippet: 'Starting Point',
        ),
      ),
      // Destination Marker (ITC Campus)
      Marker(
        markerId: const MarkerId('itc_destination'),
        position: _itcPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Institute of Technology of Cambodia',
          snippet: 'Destination',
        ),
      ),
    ]);
  }

  /// Center map back to ETEC Center
  void _recenterToEtec() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: _etecPosition, zoom: 16.0),
      ),
    );
  }

  /// Fetches actual road navigation polyline using Google Directions API
  Future<void> _fetchDirectionsRoute() async {
    setState(() => _isLoadingRoute = true);

    final polylinePoints = PolylinePoints(apiKey: _googleApiKey);

    try {
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_etecPosition.latitude, _etecPosition.longitude),
          destination: PointLatLng(
            _itcPosition.latitude,
            _itcPosition.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        final List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Direct distance calculation between coordinates
        final double distanceInMeters = Geolocator.distanceBetween(
          _etecPosition.latitude,
          _etecPosition.longitude,
          _itcPosition.latitude,
          _itcPosition.longitude,
        );

        setState(() {
          _distanceText = '${(distanceInMeters / 1000).toStringAsFixed(2)} km';

          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('etec_to_itc_road_route'),
              points: polylineCoordinates, // Actual turn-by-turn road points
              color: AppTheme.primary,
              width: 6,
            ),
          );
        });

        _fitBoundsToRoute();
      } else {
        Get.snackbar(
          'Route Error',
          result.errorMessage ??
              'Could not calculate road route. Check Directions API.',
          snackPosition: SnackPosition.BOTTOM,
        );
        log("${result.errorMessage}");
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch directions: $e');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  /// Fits camera bounds to present both markers in view comfortably
  void _fitBoundsToRoute() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        _etecPosition.latitude < _itcPosition.latitude
            ? _etecPosition.latitude
            : _itcPosition.latitude,
        _etecPosition.longitude < _itcPosition.longitude
            ? _etecPosition.longitude
            : _itcPosition.longitude,
      ),
      northeast: LatLng(
        _etecPosition.latitude > _itcPosition.latitude
            ? _etecPosition.latitude
            : _itcPosition.latitude,
        _etecPosition.longitude > _itcPosition.longitude
            ? _etecPosition.longitude
            : _itcPosition.longitude,
      ),
    );

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.surfaceOf(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      body: Stack(
        children: [
          // Main Google Map View
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _etecPosition,
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Top Floating Search Bar Header
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search events, rooms...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),

          // Action Floating Action Buttons
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                _FloatingMapButton(icon: Icons.layers, onPressed: () {}),
                const SizedBox(height: 12),
                _FloatingMapButton(
                  icon: Icons.my_location,
                  onPressed: _recenterToEtec,
                ),
              ],
            ),
          ),

          // Bottom Sheet Card Widget matching your design layout
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Institute of Technology of Cambodia',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Russian Federation Blvd. (110), Phnom Penh',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoadingRoute ? null : _fetchDirectionsRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoadingRoute
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'confirm_location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _distanceText != null
                            ? 'Distance: $_distanceText from ETEC to ITC'
                            : 'Distance: Fetching road route...',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
