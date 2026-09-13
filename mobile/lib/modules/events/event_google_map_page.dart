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

  static const String _googleApiKey = "AIzaSyBTzZVtm0j7PyCGPy7xKlHG0R5W_4dHAX0";

  // ITC Destination Coordinates
  static const LatLng _itcPosition = LatLng(11.5703975, 104.8980857);

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  String? _distanceText;
  String? _durationText;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _markers.add(
      const Marker(
        markerId: MarkerId('itc_campus'),
        position: _itcPosition,
        infoWindow: InfoWindow(title: 'Institute of Technology of Cambodia'),
      ),
    );
  }

  Future<Position?> _getUserCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permissions are denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error', 'Location permissions are permanently denied.');
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _connectToITC() async {
    setState(() => _isLoadingRoute = true);

    final position = await _getUserCurrentLocation();
    if (position == null) {
      setState(() => _isLoadingRoute = false);
      return;
    }

    final userLatLng = LatLng(position.latitude, position.longitude);

    // Calculate straight line distance (in meters)
    final distanceInMeters = Geolocator.distanceBetween(
      userLatLng.latitude,
      userLatLng.longitude,
      _itcPosition.latitude,
      _itcPosition.longitude,
    );

    // Fetch polylines from Google Directions API
    // 1. Pass the API key to the PolylinePoints constructor
    final polylinePoints = PolylinePoints(apiKey: _googleApiKey);

    // 2. Pass origin, destination, and mode inside PolylineRequest
    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(userLatLng.latitude, userLatLng.longitude),
        destination: PointLatLng(_itcPosition.latitude, _itcPosition.longitude),
        mode: TravelMode.driving,
      ),
    );

    final List<LatLng> polylineCoordinates = [];
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      // Direct straight line fallback if route fails
      polylineCoordinates.addAll([userLatLng, _itcPosition]);
    }

    setState(() {
      _isLoadingRoute = false;
      _distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';

      // User Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );

      // Route Polyline
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_itc'),
          points: polylineCoordinates,
          color: AppTheme.primary,
          width: 5,
        ),
      );
    });

    // Fit view to include both points
    LatLngBounds bounds;
    if (userLatLng.latitude <= _itcPosition.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(
          userLatLng.latitude,
          userLatLng.longitude < _itcPosition.longitude
              ? userLatLng.longitude
              : _itcPosition.longitude,
        ),
        northeast: LatLng(
          _itcPosition.latitude,
          userLatLng.longitude > _itcPosition.longitude
              ? userLatLng.longitude
              : _itcPosition.longitude,
        ),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(
          _itcPosition.latitude,
          userLatLng.longitude < _itcPosition.longitude
              ? userLatLng.longitude
              : _itcPosition.longitude,
        ),
        northeast: LatLng(
          userLatLng.latitude,
          userLatLng.longitude > _itcPosition.longitude
              ? userLatLng.longitude
              : _itcPosition.longitude,
        ),
      );
    }

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
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _itcPosition,
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Top Search Bar
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
                        hintText: 'search_events_hint'.tr,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
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

          // Action Buttons
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                _FloatingMapButton(icon: Icons.layers, onPressed: () {}),
                const SizedBox(height: 12),
                _FloatingMapButton(
                  icon: Icons.my_location,
                  onPressed: () async {
                    final pos = await _getUserCurrentLocation();
                    if (pos != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(pos.latitude, pos.longitude),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom Detail Sheet
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
                    onPressed: _isLoadingRoute ? null : _connectToITC,
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
                        : Text(
                            'confirm_location'.tr,
                            style: const TextStyle(
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
                            ? 'Distance: $_distanceText to ITC'
                            : '20 places found nearby',
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
