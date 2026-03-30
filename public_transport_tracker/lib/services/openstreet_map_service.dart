import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'notification_service.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  Location location = Location();
  MapController? _mapController;
  List<Marker> _markers = [];
  Position? _currentPosition;
  
  // Default center (Galle, Sri Lanka)
  static const LatLng defaultCenter = LatLng(6.0329, 80.2168);

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    return true;
  }

  /// Get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!await checkLocationPermission()) return null;
      
      LocationData locationData = await location.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Create OpenStreetMap widget
  Widget createMap({
    LatLng? center,
    double zoom = 15.0,
    List<Marker> markers = const [],
    Function(LatLng)? onTap,
    Function(MapController)? onMapCreated,
    VoidCallback? onMapReady,
    bool showUserLocation = true,
  }) {
    return FutureBuilder<LatLng?>(
      future: center != null ? Future.value(center) : getCurrentLocation(),
      builder: (context, snapshot) {
        final mapCenter = snapshot.data ?? defaultCenter;
        
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: zoom,
            onMapReady: () {
              if (onMapCreated != null && _mapController != null) {
                onMapCreated(_mapController!);
              }
              onMapReady?.call();
            },
            onTap: (tapPosition, point) {
              if (onTap != null) {
                onTap(point);
              }
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.public_transport_tracker',
              maxZoom: 19,
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [..._markers, ...markers],
            ),
          ],
        );
      },
    );
  }

  /// Initialize map controller
  void initializeController() {
    _mapController = MapController();
  }

  /// Create a marker for bus location with real-time tracking
  Marker createBusMarker({
    required String markerId,
    required LatLng position,
    String? busNumber,
    VoidCallback? onTap,
    double? heading, // For bus direction indicator
  }) {
    return Marker(
      key: Key(markerId),
      point: position,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: (heading ?? 0.0) * (3.14159 / 180), // Convert degrees to radians
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 20,
                ),
                if (busNumber != null)
                  Text(
                    busNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Create a marker for bus stop
  Marker createBusStopMarker({
    required String markerId,
    required LatLng position,
    String? stopName,
    VoidCallback? onTap,
  }) {
    return Marker(
      key: Key(markerId),
      point: position,
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            Icons.bus_alert,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  /// Create a marker for user location
  Marker createUserMarker({
    required String markerId,
    required LatLng position,
    VoidCallback? onTap,
  }) {
    return Marker(
      key: Key(markerId),
      point: position,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Add marker to map
  void addMarker(Marker marker) {
    // Remove existing marker with same key
    _markers.removeWhere((m) => m.key == marker.key);
    _markers.add(marker);
  }

  /// Remove marker by key
  void removeMarker(String markerId) {
    _markers.removeWhere((marker) => marker.key == Key(markerId));
  }

  /// Clear all markers
  void clearMarkers() {
    _markers.clear();
  }

  /// Update bus location
  void updateBusLocation(String busId, double lat, double lng, String routeNumber) {
    removeMarker(busId);
    final marker = createBusMarker(
      markerId: busId,
      position: LatLng(lat, lng),
      busNumber: routeNumber,
    );
    addMarker(marker);
  }

  /// Animate camera to location
  Future<void> animateToLocation(LatLng target, {double zoom = 15.0}) async {
    if (_mapController != null) {
      _mapController!.move(target, zoom);
    }
  }

  /// Move camera to show multiple points
  void fitBounds(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    
    _mapController!.fitCamera(CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)));
  }

  /// Get distance between two points in meters
  double getDistance(LatLng point1, LatLng point2) {
    return Distance().as(LengthUnit.Meter, point1, point2);
  }

  /// Calculate bearing between two points
  double getBearing(LatLng from, LatLng to) {
    return Distance().bearing(from, to);
  }

  /// Start location tracking
  Stream<LocationData> startLocationTracking() {
    return location.onLocationChanged;
  }

  /// Enable real-time location updates
  Future<void> enableLocationTracking({
    required Function(LatLng) onLocationUpdate,
  }) async {
    if (!await checkLocationPermission()) return;

    location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        final newPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        onLocationUpdate(newPosition);
        
        // Update user marker
        final userMarker = createUserMarker(
          markerId: 'user_location',
          position: newPosition,
        );
        addMarker(userMarker);
      }
    });
  }

  /// Bus proximity notification service
  Future<void> notifyWhenBusApproaches({
    required String busId,
    required LatLng busLocation,
    required LatLng userLocation,
    required String routeNumber,
    double proximityThreshold = 500.0, // 500 meters
  }) async {
    final distance = getDistance(busLocation, userLocation);
    
    if (distance <= proximityThreshold) {
      await NotificationService().showBusArrivalNotification(
        busNumber: routeNumber,
        stopName: 'Your Location',
        estimatedMinutes: (distance / 100).round().clamp(1, 10),
      );
    }
  }

  /// Get nearby buses within radius
  List<Marker> getNearbyBuses(LatLng userLocation, double radiusInMeters) {
    return _markers.where((marker) {
      if (marker.key.toString().contains('bus_')) {
        final distance = getDistance(userLocation, marker.point);
        return distance <= radiusInMeters;
      }
      return false;
    }).toList();
  }

  /// Search for locations (mock implementation - can be enhanced with real geocoding)
  Future<List<LatLng>> searchLocation(String query) async {
    // Mock search results for demonstration
    // In a real app, you would use a geocoding service
    Map<String, LatLng> mockLocations = {
      'galle': LatLng(6.0329, 80.2168),
      'colombo': LatLng(6.9271, 79.8612),
      'kandy': LatLng(7.2906, 80.6337),
      'matara': LatLng(5.9549, 80.5550),
      'negombo': LatLng(7.2084, 79.8614),
    };
    
    List<LatLng> results = [];
    query = query.toLowerCase();
    
    mockLocations.forEach((key, value) {
      if (key.contains(query)) {
        results.add(value);
      }
    });
    
    return results;
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Format time estimate based on distance and speed
  String formatTimeEstimate(double distanceInMeters, double speedKmh) {
    double timeHours = distanceInMeters / 1000 / speedKmh;
    int timeMinutes = (timeHours * 60).round();
    
    if (timeMinutes < 60) {
      return '${timeMinutes}min';
    } else {
      int hours = timeMinutes ~/ 60;
      int minutes = timeMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  // Getters
  MapController? get mapController => _mapController;
  List<Marker> get markers => _markers;
  LatLng get defaultLocation => defaultCenter;
  Position? get currentPosition => _currentPosition;
}