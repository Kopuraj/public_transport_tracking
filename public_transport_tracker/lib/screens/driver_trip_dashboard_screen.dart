import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';
import '../services/socket_service.dart';

class DriverTripDashboardScreen extends StatefulWidget {
  final String? tripId;
  const DriverTripDashboardScreen({super.key, this.tripId});

  @override
  State<DriverTripDashboardScreen> createState() => _DriverTripDashboardScreenState();
}

class _DriverTripDashboardScreenState extends State<DriverTripDashboardScreen> {
  int _passengerCount = 24;
  final int _maxCapacity = 55;

  // Real-time tracking variables
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  String? _currentTripId;
  String _statusText = 'Initializing...';
  double _currentCompletion = 0.0;

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
    } else {
      _startSimulatedTrip();
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  void _startSimulatedTrip() {
    // This would normally come from ApiService().initializeTrip
    setState(() {
      _currentTripId = "TRIP_${DateTime.now().millisecondsSinceEpoch}";
      _isTracking = true;
      _statusText = 'ONLINE';
    });
    _startTracking();
  }

  void _startTracking() async {
    bool hasPermission = await MapService().checkLocationPermission();
    if (!hasPermission) {
      setState(() => _statusText = 'PERMISSION DENIED');
      return;
    }

    SocketService().connect();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (_currentTripId != null) {
        debugPrint('📡 Sending GPS: ${position.latitude}, ${position.longitude}');
        ApiService().sendGpsUpdate(
          tripId: _currentTripId!,
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          accuracy: position.accuracy,
        );
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

  void _stopTracking() {
    _positionSubscription?.cancel();
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

  void _updateCrowdLevel() {
    if (_currentTripId == null) return;
    
    double occupancy = _passengerCount / _maxCapacity;
    String level = occupancy < 0.5 ? 'available' : occupancy < 0.8 ? 'standing' : 'full';
    
    // Send report to backend
    ApiService().submitCrowdReport(
      tripId: _currentTripId!,
      crowdLevel: level,
      userLatitude: 0, // In real CONDUCTOR use, would be current loc
      userLongitude: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    double occupancyPercentage = (_passengerCount / _maxCapacity) * 100;
    Color crowdingColor = occupancyPercentage < 50
        ? Colors.green
        : occupancyPercentage < 80
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Color(0xFF0D131B)),
        ),
        title: Text(
          'Trip Dashboard',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
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
              padding: EdgeInsets.all(16),
              color: Color(0xFFF0F5FF),
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
                            'Route 502: Galle - Hapugala',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Vehicle: NB-4562 (Leyland Viking)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999CA6),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.45,
                      minHeight: 6,
                      backgroundColor: Color(0xFFE0E6F2),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF136AEC)),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '45% of route completed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999CA6),
                    ),
                  ),
                ],
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
                      color: Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: crowdingColor.withValues(alpha: 0.3)),
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
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            valueColor: AlwaysStoppedAnimation<Color>(crowdingColor),
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
                          child: Icon(Icons.location_on, color: Color(0xFF136AEC)),
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
                        Icon(Icons.arrow_forward_ios, color: Color(0xFF999CA6), size: 16),
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
                    {'name': 'Karapitiya Junction', 'time': '4 mins', 'distance': '1.2 km'},
                    {'name': 'Galle City Center', 'time': '12 mins', 'distance': '3.4 km'},
                    {'name': 'Main Bus Terminal', 'time': '18 mins', 'distance': '5.1 km'},
                  ].map((stop) => Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF136AEC), size: 20),
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
                  )),
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
                        Navigator.pushNamed(context, '/emergency-alert');
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
                  Text('Route: Galle - Hapugala'),
                  Text('Vehicle: NB-4562'),
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

        Navigator.pushReplacementNamed(
          context,
          '/trip-summary',
          arguments: {
            'tripId': _currentTripId,
            'vehicleNumber': 'NB-4562',
            'route': 'Galle - Hapugala',
            'duration': _formatDuration(_getElapsedTime()),
            'totalPassengers': _passengerCount,
            'endTime': DateTime.now(),
          },
        );
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
    return Duration(hours: 0, minutes: 45); // Example duration
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes';
  }
}
