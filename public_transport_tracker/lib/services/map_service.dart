import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  Location location = Location();
  
  // Default center (you can change this to your city)
  static const LatLng defaultCenter = LatLng(13.0827, 80.2707); // Chennai, India

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

  /// Create a basic FlutterMap widget
  Widget createMap({
    required LatLng center,
    double zoom = 15.0,
    List<Marker> markers = const [],
    List<Polyline> polylines = const [],
    Function(LatLng)? onTap,
    String tileProvider = 'openstreetmap',
    MapController? mapController,
    VoidCallback? onMapReady, // Add this
  }) {
    
    String getTileUrl() {
      switch (tileProvider) {
        case 'cartodb':
          return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
        case 'stamen':
          return 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg';
        case 'openstreetmap':
        default:
          return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      }
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          onMapReady: onMapReady, // Use the callback
          onTap: onTap != null ? (tapPosition, point) => onTap(point) : null,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // Multiple tile layer options for better compatibility
          TileLayer(
            urlTemplate: getTileUrl(),
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.public_transport_tracker',
            maxZoom: 19,
            // Add fallback and error handling
            fallbackUrl: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          ),
        
        // Polylines (routes, paths)
        if (polylines.isNotEmpty)
          PolylineLayer(polylines: polylines),
        
        // Markers (buses, stops, etc.)
        if (markers.isNotEmpty)
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  /// Create a marker for bus location
  Marker createBusMarker(LatLng position, {String? busNumber}) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.directions_bus,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// Create a marker for bus stop
  Marker createBusStopMarker(LatLng position, {String? stopName}) {
    return Marker(
      point: position,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.location_on,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  /// Create a marker for user location
  Marker createUserMarker(LatLng position) {
    return Marker(
      point: position,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  /// Create a polyline for route
  Polyline createRoutePolyline(List<LatLng> points, {Color? color}) {
    return Polyline(
      points: points,
      strokeWidth: 4.0,
      color: color ?? Colors.blue,
    );
  }

  /// Calculate distance between two points (in meters)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Get location updates stream
  Stream<LatLng> getLocationUpdates() {
    return location.onLocationChanged.map((locationData) =>
        LatLng(locationData.latitude!, locationData.longitude!));
  }
}