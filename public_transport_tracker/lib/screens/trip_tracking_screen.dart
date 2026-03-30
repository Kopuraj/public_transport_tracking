import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/socket_service.dart';
import '../services/map_service.dart';
import '../services/api_service.dart';

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  // Selected route and trip
  Map<String, dynamic>? _selectedRoute;
  Map<String, dynamic>? _selectedTrip;

  // Live tracking state
  LatLng _busLocation = const LatLng(6.0329, 80.2168); // Default: Galle
  String _etaText = '--';
  String _occupancyText = 'Unknown';
  bool _isMapReady = false;

  // Loading states
  bool _loadingRoutes = true;
  bool _loadingTrips = false;
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _activeTrips = [];

  StreamSubscription? _gpsSubscription;
  StreamSubscription? _crowdSubscription;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    SocketService().connect();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accept route passed from Routes screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && _selectedRoute == null) {
      _selectRoute(args);
    }
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _crowdSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() => _loadingRoutes = true);
    try {
      final result = await _apiService.getAllRoutes();
      if (result['success'] == true) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(result['routes'] ?? []);
          _loadingRoutes = false;
        });
      } else {
        setState(() => _loadingRoutes = false);
      }
    } catch (e) {
      setState(() => _loadingRoutes = false);
    }
  }

  Future<void> _selectRoute(Map<String, dynamic> route) async {
    setState(() {
      _selectedRoute = route;
      _selectedTrip = null;
      _activeTrips = [];
      _loadingTrips = true;
    });

    try {
      final routeId = route['id'] ?? '';
      final result = await _apiService.getActiveTripsOnRoute(routeId);
      if (result['success'] == true) {
        setState(() {
          _activeTrips = List<Map<String, dynamic>>.from(result['trips'] ?? []);
          _loadingTrips = false;
        });
      } else {
        setState(() => _loadingTrips = false);
      }
    } catch (e) {
      setState(() => _loadingTrips = false);
    }
  }

  void _selectTrip(Map<String, dynamic> trip) {
    _gpsSubscription?.cancel();
    _crowdSubscription?.cancel();

    setState(() => _selectedTrip = trip);

    final tripId = trip['id'] ?? '';
    SocketService().emit('subscribe-trip', tripId);

    _gpsSubscription = SocketService().gpsUpdates.listen((data) {
      if (!mounted) return;
      if (data['tripId'] == tripId && data['location'] != null) {
        setState(() {
          _busLocation = LatLng(
            (data['location']['latitude'] as num).toDouble(),
            (data['location']['longitude'] as num).toDouble(),
          );
          if (data['eta'] != null) {
            _etaText = '${data['eta']['etaMinutes']} min';
          }
        });
        if (_isMapReady) {
          _mapController.move(_busLocation, _mapController.camera.zoom);
        }
      }
    });

    _crowdSubscription = SocketService().crowdUpdates.listen((data) {
      if (!mounted) return;
      setState(() {
        _occupancyText =
            data['crowdLevel']?.toString().toUpperCase() ?? 'Unknown';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          _selectedRoute == null
              ? 'Track a Bus'
              : '${_selectedRoute!['from']} → ${_selectedRoute!['to']}',
          style: const TextStyle(
              color: Color(0xFF0D131B),
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedRoute != null)
            TextButton(
              onPressed: () => setState(() {
                _selectedRoute = null;
                _selectedTrip = null;
                _gpsSubscription?.cancel();
                _crowdSubscription?.cancel();
              }),
              child: const Text('Change Route',
                  style: TextStyle(color: Color(0xFF136AEC))),
            ),
        ],
      ),
      body: _selectedRoute == null
          ? _buildRoutePicker()
          : _selectedTrip == null
              ? _buildTripPicker()
              : _buildLiveTracking(),
    );
  }

  // Step 1: Pick a route
  Widget _buildRoutePicker() {
    if (_loadingRoutes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No routes available',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRoutes,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF136AEC),
                  foregroundColor: Colors.white),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Select a route to track',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D131B))),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _routes.length,
            itemBuilder: (context, index) {
              final route = _routes[index];
              return GestureDetector(
                onTap: () => _selectRoute(route),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E6F2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF136AEC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(route['routeNumber'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${route['from']} → ${route['to']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B)),
                            ),
                            Text(
                              '${route['fare']} · ${route['frequency']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF999CA6)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF999CA6)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Step 2: Pick an active trip on that route
  Widget _buildTripPicker() {
    if (_loadingTrips) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route info header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E6F2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.route, color: Color(0xFF136AEC)),
              const SizedBox(width: 10),
              Text(
                'Route ${_selectedRoute!['routeNumber']} — ${_selectedRoute!['from']} to ${_selectedRoute!['to']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF0D131B)),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Active buses on this route',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D131B))),
        ),
        const SizedBox(height: 8),

        if (_activeTrips.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_bus_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No active buses on this route right now',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('A driver needs to start a trip first',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _selectRoute(_selectedRoute!),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136AEC),
                        foregroundColor: Colors.white),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _activeTrips.length,
              itemBuilder: (context, index) {
                final trip = _activeTrips[index];
                return GestureDetector(
                  onTap: () => _selectTrip(trip),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E6F2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.directions_bus,
                              color: Colors.green.shade600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bus ${trip['vehicleId'] ?? 'Unknown'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D131B)),
                              ),
                              Text(
                                'Trip ID: ${trip['id']?.toString().substring(0, 8) ?? ''}...',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF999CA6)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF999CA6)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Step 3: Live tracking map
  Widget _buildLiveTracking() {
    final stops = (_selectedRoute!['stops'] as List? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();

    Color occupancyColor = Colors.green;
    if (_occupancyText == 'HEAVY' || _occupancyText == 'FULL') {
      occupancyColor = Colors.red;
    } else if (_occupancyText == 'MEDIUM' || _occupancyText == 'STANDING') {
      occupancyColor = Colors.orange;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Map
          Container(
            height: 260,
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E6F2)),
            ),
            child: MapService().createMap(
              center: _busLocation,
              zoom: 14,
              mapController: _mapController,
              onMapReady: () => setState(() => _isMapReady = true),
              markers: [
                MapService().createBusMarker(
                  _busLocation,
                  busNumber: _selectedRoute!['routeNumber'],
                ),
                ...stops.map((stop) {
                  if (stop['lat'] != null && stop['lng'] != null) {
                    return MapService().createBusStopMarker(
                      LatLng((stop['lat'] as num).toDouble(),
                          (stop['lng'] as num).toDouble()),
                      stopName: stop['name'],
                    );
                  }
                  return null;
                }).whereType<Marker>(),
              ],
            ),
          ),

          // ETA & Occupancy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.schedule,
                    label: 'ETA',
                    value: _etaText,
                    color: const Color(0xFF136AEC),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.people,
                    label: 'Occupancy',
                    value: _occupancyText,
                    color: occupancyColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Route stops list
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E6F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Route Stops',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D131B))),
                const SizedBox(height: 12),
                ...stops.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stop = entry.value;
                  final isFirst = i == 0;
                  final isLast = i == stops.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst || isLast
                                ? const Color(0xFF136AEC)
                                : const Color(0xFFE0E6F2),
                            border: Border.all(
                                color: const Color(0xFF136AEC), width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(stop['name'] ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isFirst || isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: const Color(0xFF0D131B))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6F2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999CA6),
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
