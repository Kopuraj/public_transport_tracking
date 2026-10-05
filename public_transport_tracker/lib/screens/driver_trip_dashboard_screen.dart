import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';
import '../services/socket_service.dart';
import 'staff_emergency_alert_screen.dart';

class DriverTripDashboardScreen extends StatefulWidget {
  final String? tripId;
  const DriverTripDashboardScreen({super.key, this.tripId});

  @override
  State<DriverTripDashboardScreen> createState() =>
      _DriverTripDashboardScreenState();
}

class _DriverTripDashboardScreenState extends State<DriverTripDashboardScreen> {
  final MapController _demoMapController = MapController();
  int _passengerCount = 0;
  int _maxCapacity = 55;

  // Real-time tracking variables
  StreamSubscription<Position>? _positionSubscription;
  Timer? _gpsHeartbeatTimer;
  bool _isTracking = false;
  String? _currentTripId;
  String _statusText = 'Initializing...';
  String _routeLabel = 'Loading route...';
  String _vehicleLabel = 'Loading vehicle...';
  double _currentCompletion = 0.0;
  DateTime _tripStartedAt = DateTime.now();
  List<Map<String, dynamic>> _routeStops = [];
  LatLng? _displayLocation;
  bool _demoMode = false;

  // Required missing variables
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.tripId != null) {
      setState(() {
        _currentTripId = widget.tripId;
        _isTracking = true;
        _statusText = 'ONLINE';
      });
      _startTracking();
      _loadTripDetails();
    } else {
      _statusText = 'TRIP NOT INITIALIZED';
    }
  }

  Future<void> _loadTripDetails() async {
    if (_currentTripId == null) return;
    try {
      final response = await _apiService.getTripDetails(_currentTripId!);
      final trip = Map<String, dynamic>.from(response['trip'] ?? {});
      final route = Map<String, dynamic>.from(trip['route'] ?? {});
      final inbound = trip['direction'] == 'inbound';
      final from = inbound ? route['to'] : route['from'];
      final to = inbound ? route['from'] : route['to'];
      final storedStops = (route['stops'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final directedStops = inbound
          ? storedStops.reversed.toList()
          : storedStops;
      final currentLocation = trip['currentLocation'];
      if (!mounted) return;
      setState(() {
        _routeLabel =
            'Route ${route['routeNumber'] ?? trip['routeId'] ?? '-'}: ${from ?? 'Unknown'} - ${to ?? 'Unknown'}';
        _vehicleLabel = 'Vehicle: ${trip['vehicleId'] ?? 'Unknown'}';
        _passengerCount = (trip['occupancy'] as num?)?.toInt() ?? 0;
        _maxCapacity = (trip['capacity'] as num?)?.toInt() ?? 55;
        _tripStartedAt =
            DateTime.tryParse(trip['startTime']?.toString() ?? '') ??
            DateTime.now();
        _routeStops = directedStops;
        if (currentLocation is Map &&
            currentLocation['latitude'] is num &&
            currentLocation['longitude'] is num) {
          _displayLocation = LatLng(
            (currentLocation['latitude'] as num).toDouble(),
            (currentLocation['longitude'] as num).toDouble(),
          );
        }
      });
    } catch (error) {
      debugPrint('Trip details unavailable: $error');
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  void _startTracking() async {
    bool hasPermission = await MapService().checkLocationPermission();
    if (!hasPermission) {
      setState(() => _statusText = 'PERMISSION DENIED');
      return;
    }

    SocketService().connect();

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (_currentTripId != null) {
        await _sendGps(initialPosition);
      }
    } catch (error) {
      debugPrint('Initial GPS fix unavailable: $error');
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          if (_currentTripId != null) {
            debugPrint(
              '📡 Sending GPS: ${position.latitude}, ${position.longitude}',
            );
            _sendGps(position);
          }
        });

    _gpsHeartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_isTracking || _currentTripId == null) return;
      try {
        if (_demoMode && _displayLocation != null) {
          await _apiService.sendGpsUpdate(
            tripId: _currentTripId!,
            latitude: _displayLocation!.latitude,
            longitude: _displayLocation!.longitude,
            speed: 0,
            accuracy: 1,
          );
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _sendGps(position);
      } catch (error) {
        debugPrint('GPS heartbeat failed: $error');
      }
    });

    // Simulate completion progress
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted || !_isTracking) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentCompletion < 0.95) {
          _currentCompletion += 0.05;
        }
      });
    });
  }

  Future<void> _sendGps(Position position) async {
    if (_currentTripId == null || _demoMode) return;
    try {
      await _apiService.sendGpsUpdate(
        tripId: _currentTripId!,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
      );
      if (mounted) {
        setState(
          () =>
              _displayLocation = LatLng(position.latitude, position.longitude),
        );
      }
      if (mounted && _statusText != 'ONLINE') {
        setState(() => _statusText = 'ONLINE');
      }
    } catch (error) {
      debugPrint('GPS update failed: $error');
      if (mounted) setState(() => _statusText = 'RECONNECTING');
    }
  }

  Future<void> _setDemoLocation(Map<String, dynamic> stop) async {
    final lat = stop['lat'] ?? stop['latitude'];
    final lng = stop['lng'] ?? stop['longitude'];
    if (lat is! num || lng is! num || _currentTripId == null) return;
    setState(() {
      _isLoading = true;
      _demoMode = true;
    });
    try {
      await _apiService.sendGpsUpdate(
        tripId: _currentTripId!,
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        speed: 0,
        accuracy: 1,
      );
      if (!mounted) return;
      setState(() => _displayLocation = LatLng(lat.toDouble(), lng.toDouble()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bus moved to ${stop['name'] ?? 'selected stop'}'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location update failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resumeDeviceGps() async {
    setState(() {
      _demoMode = false;
      _isLoading = true;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _sendGps(position);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device GPS tracking resumed')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not resume device GPS: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _stopTracking() {
    _positionSubscription?.cancel();
    _gpsHeartbeatTimer?.cancel();
    _isTracking = false;
    SocketService().disconnect();
  }

  void _increasePassengers() {
    setState(() {
      if (_passengerCount < _maxCapacity) {
        _passengerCount++;
      }
    });
    _updateCrowdLevel();
  }

  void _decreasePassengers() {
    setState(() {
      if (_passengerCount > 0) {
        _passengerCount--;
      }
    });
    _updateCrowdLevel();
  }

  Future<void> _updateCrowdLevel() async {
    if (_currentTripId == null) return;
    try {
      await _apiService.updateTripOccupancy(
        tripId: _currentTripId!,
        occupancy: _passengerCount,
      );
    } catch (error) {
      debugPrint('Occupancy update failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTripId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF0D131B)),
          ),
          title: const Text(
            'Trip Dashboard',
            style: TextStyle(
              color: Color(0xFF0D131B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No active trip found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D131B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a trip from Trip Initialization so passenger tracking can receive real-time updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF666B77)),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/trip-initialization',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF136AEC),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go To Trip Initialization'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    double occupancyPercentage = (_passengerCount / _maxCapacity) * 100;
    Color crowdingColor = occupancyPercentage < 50
        ? Colors.green
        : occupancyPercentage < 80
        ? Colors.orange
        : Colors.red;
    final routePoints = _routeStops
        .map((stop) {
          final lat = stop['lat'] ?? stop['latitude'];
          final lng = stop['lng'] ?? stop['longitude'];
          return lat is num && lng is num
              ? LatLng(lat.toDouble(), lng.toDouble())
              : null;
        })
        .whereType<LatLng>()
        .toList();
    final demoMarkers = _routeStops
        .map((stop) {
          final lat = stop['lat'] ?? stop['latitude'];
          final lng = stop['lng'] ?? stop['longitude'];
          if (lat is! num || lng is! num) return null;
          return Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: 42,
            height: 42,
            child: GestureDetector(
              onTap: () => _setDemoLocation(stop),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: Colors.white, size: 24),
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Color(0xFF0D131B)),
        ),
        title: Text(
          'Active Trip',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'End active trip',
            onPressed: _isLoading ? null : _showEndTripDialog,
            icon: const Icon(Icons.stop_circle, color: Colors.red),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFE1F6EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF087A4B)),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF087A4B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Status Header
            Container(
              margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF101828), Color(0xFF25324A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x24101828),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _routeLabel,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_bus_filled_rounded,
                                  size: 14,
                                  color: Color(0xFFB9C2D0),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _vehicleLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB9C2D0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0x3320C77A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52E3A2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _currentCompletion,
                      minHeight: 6,
                      backgroundColor: Color(0xFF3A465C),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF20C77A),
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${(_currentCompletion * 100).toStringAsFixed(0)}% of route completed',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB9C2D0)),
                  ),
                ],
              ),
            ),

            if (routePoints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Demo Bus Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap a red route stop to move the bus there for your demonstration.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(
                              _demoMode ? Icons.touch_app : Icons.gps_fixed,
                              size: 16,
                            ),
                            label: Text(_demoMode ? 'DEMO MODE' : 'DEVICE GPS'),
                            backgroundColor: _demoMode
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                          ),
                          const Spacer(),
                          if (_demoMode)
                            TextButton.icon(
                              onPressed: _isLoading ? null : _resumeDeviceGps,
                              icon: const Icon(Icons.gps_fixed),
                              label: const Text('Use Device GPS'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MapService().createMap(
                            center: _displayLocation ?? routePoints.first,
                            zoom: 11,
                            mapController: _demoMapController,
                            onMapReady: () {
                              if (routePoints.length > 1) {
                                _demoMapController.fitCamera(
                                  CameraFit.bounds(
                                    bounds: LatLngBounds.fromPoints(
                                      routePoints,
                                    ),
                                    padding: const EdgeInsets.all(36),
                                  ),
                                );
                              }
                            },
                            polylines: routePoints.length > 1
                                ? [
                                    MapService().createRoutePolyline(
                                      routePoints,
                                    ),
                                  ]
                                : const [],
                            markers: [
                              ...demoMarkers,
                              if (_displayLocation != null)
                                MapService().createBusMarker(_displayLocation!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _routeStops.asMap().entries.map((entry) {
                          final index = entry.key;
                          return ActionChip(
                            avatar: const Icon(Icons.location_on, size: 16),
                            label: Text(
                              _routeStops[index]['name']?.toString() ??
                                  'Stop ${index + 1}',
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _setDemoLocation(_routeStops[index]),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Passenger Count Control
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passenger Count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: crowdingColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Passengers',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999CA6),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '$_passengerCount / $_maxCapacity',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: crowdingColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: crowdingColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${occupancyPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: crowdingColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  occupancyPercentage < 50
                                      ? 'Plenty of seats'
                                      : occupancyPercentage < 80
                                      ? 'Moderately crowded'
                                      : 'Very crowded',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: crowdingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: occupancyPercentage / 100,
                            minHeight: 8,
                            backgroundColor: Color(0xFFE0E6F2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              crowdingColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Passenger Counter Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _decreasePassengers,
                      icon: Icon(Icons.remove),
                      label: Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _increasePassengers,
                      icon: Icon(Icons.add),
                      label: Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Next Stop Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Stop',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE0E6F2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF136AEC).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Color(0xFF136AEC),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Karapitiya Junction',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '4 mins away • 1.2 km',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF999CA6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF999CA6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Stops List
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Stops',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  ...[
                    {
                      'name': 'Karapitiya Junction',
                      'time': '4 mins',
                      'distance': '1.2 km',
                    },
                    {
                      'name': 'Galle City Center',
                      'time': '12 mins',
                      'distance': '3.4 km',
                    },
                    {
                      'name': 'Main Bus Terminal',
                      'time': '18 mins',
                      'distance': '5.1 km',
                    },
                  ].map(
                    (stop) => Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Color(0xFF136AEC),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop['name'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D131B),
                                  ),
                                ),
                                Text(
                                  '${stop['time']} • ${stop['distance']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF999CA6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to emergency alert
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffEmergencyAlertScreen(
                              tripId: _currentTripId,
                              routeLabel: _routeLabel,
                              passengerCount: _passengerCount,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.warning),
                      label: Text('Report Emergency'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _showEndTripDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('End Trip'),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showEndTripDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('End Trip'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to end this trip?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Summary:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(_routeLabel),
                  Text(_vehicleLabel),
                  Text('Duration: ${_formatDuration(_getElapsedTime())}'),
                  Text('Total Passengers: ${_passengerCount.toString()}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('End Trip'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _endTrip();
    }
  }

  Future<void> _endTrip() async {
    setState(() => _isLoading = true);

    try {
      // Stop GPS updates first
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // End trip via API
      final response = await _apiService.endTrip(_currentTripId!);

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to end trip');
      }
    } catch (e) {
      debugPrint('❌ End trip error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Duration _getElapsedTime() {
    // Calculate elapsed time since trip start
    // In a real app, this would be based on actual trip start time from API
    return DateTime.now().difference(_tripStartedAt);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes';
  }
}
