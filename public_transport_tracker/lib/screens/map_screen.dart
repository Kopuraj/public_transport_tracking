import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();
  late MapController _mapController;
  
  LatLng _currentCenter = MapService.defaultCenter;
  LatLng? _userLocation;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Get user's current location
    LatLng? userLocation = await _mapService.getCurrentLocation();
    
    if (userLocation != null) {
      setState(() {
        _userLocation = userLocation;
        _currentCenter = userLocation;
        _markers = [_mapService.createUserMarker(userLocation)];
      });
      
      // Move map to user location
      _mapController.move(userLocation, 15.0);
    }
    
    // Add some sample bus stops and buses
    _addSampleData();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _addSampleData() {
    // Sample bus stops around user location or default center
    LatLng center = _userLocation ?? _currentCenter;
    
    List<LatLng> busStops = [
      LatLng(center.latitude + 0.01, center.longitude + 0.01),
      LatLng(center.latitude - 0.01, center.longitude + 0.005),
      LatLng(center.latitude + 0.005, center.longitude - 0.01),
    ];
    
    // Add bus stop markers
    for (LatLng stop in busStops) {
      _markers.add(_mapService.createBusStopMarker(stop));
    }
    
    // Sample bus location
    LatLng busLocation = LatLng(center.latitude + 0.005, center.longitude + 0.007);
    _markers.add(_mapService.createBusMarker(busLocation, busNumber: "45A"));
    
    // Sample route polyline
    List<LatLng> routePoints = [
      center,
      ...busStops,
      busLocation,
    ];
    
    _polylines.add(_mapService.createRoutePolyline(routePoints));
  }

  void _onMapTap(LatLng point) {
    // Add a custom marker where user tapped
    setState(() {
      _markers.add(
        Marker(
          point: point,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              Icons.place,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added marker at ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenStreetMap - FREE!'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () async {
              LatLng? currentLocation = await _mapService.getCurrentLocation();
              if (currentLocation != null) {
                _mapController.move(currentLocation, 15.0);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            )
          : Stack(
              children: [
                // Wrap the map in a SizedBox to ensure proper constraints
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: _mapService.createMap(
                    center: _currentCenter,
                    zoom: 15.0,
                    markers: _markers,
                    polylines: _polylines,
                    onTap: _onMapTap,
                    tileProvider: 'cartodb', // Better for web browsers
                  ),
                ),
                
                // Map controls overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Map Features:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.green, size: 16),
                              Text(' Your Location  '),
                              Icon(Icons.directions_bus, color: Colors.blue, size: 16),
                              Text(' Bus  '),
                              Icon(Icons.location_on, color: Colors.red, size: 16),
                              Text(' Bus Stop'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Zoom to show all markers
          if (_markers.isNotEmpty) {
            _mapController.move(_currentCenter, 13.0);
          }
        },
        child: Icon(Icons.zoom_out_map),
      ),
    );
  }
}