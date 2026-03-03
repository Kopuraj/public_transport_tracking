import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'driver_trip_dashboard_screen.dart';

class TripInitializationScreen extends StatefulWidget {
  const TripInitializationScreen({super.key});

  @override
  State<TripInitializationScreen> createState() => _TripInitializationScreenState();
}

class _TripInitializationScreenState extends State<TripInitializationScreen> {
  String _selectedVehicle = 'NB-4562';
  String _selectedRouteId = 'route_502';
  String _selectedRouteName = '502: Galle - Hapugala';
  bool _isInitializing = false;
  List<dynamic> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final response = await ApiService().getAllRoutes();
      if (response['success'] && response['routes'] != null) {
        setState(() {
          _routes = response['routes'];
          if (_routes.isNotEmpty) {
            _selectedRouteId = _routes[0]['id'];
            _selectedRouteName = '${_routes[0]['routeNumber']}: ${_routes[0]['name']}';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
    }
  }

  Future<void> _handleStartTrip() async {
    setState(() => _isInitializing = true);
    try {
      final response = await ApiService().initializeTrip(
        vehicleId: _selectedVehicle,
        routeId: _selectedRouteId,
      );

      if (response['success']) {
        final tripId = response['tripId'];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DriverTripDashboardScreen(tripId: tripId),
            ),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to start trip');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Do you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ApiService().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/welcome');
                      }
                    },
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          child: Icon(Icons.arrow_back, color: Color(0xFF0D131B)),
        ),
        title: Text(
          'Trip Initialization',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: EdgeInsets.all(16),
              color: Color(0xFFF0F5FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Duty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Configure your session before starting GPS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999CA6),
                    ),
                  ),
                ],
              ),
            ),

            // Select Vehicle Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE0E6F2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_bus, color: Color(0xFF136AEC)),
                            SizedBox(width: 12),
                            Text(
                              _selectedVehicle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D131B),
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, color: Color(0xFF999CA6), size: 16),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'System Ready: GPS sharing will begin after launch start',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF136AEC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Select Route Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Route',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE0E6F2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.route, color: Color(0xFF136AEC)),
                            SizedBox(width: 12),
                            Text(
                              _selectedRouteName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D131B),
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, color: Color(0xFF999CA6), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Route Preview Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE0E6F2)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 48, color: Color(0xFF136AEC).withValues(alpha: 0.5)),
                              SizedBox(height: 8),
                              Text(
                                'Route Preview Map',
                                style: TextStyle(
                                  color: Color(0xFF4C6B9A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: Text(
                              'LIVE TRAFFIC READY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // System Ready Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Ready',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'GPS sharing will begin after tapping start',
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

            SizedBox(height: 20),

            // Start Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isInitializing ? null : _handleStartTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF136AEC),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isInitializing 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Start Trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),

            // End Trip Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'End Trip Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
