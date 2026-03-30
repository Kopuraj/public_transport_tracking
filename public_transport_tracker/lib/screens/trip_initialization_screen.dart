import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'driver_trip_dashboard_screen.dart';

class TripInitializationScreen extends StatefulWidget {
  const TripInitializationScreen({super.key});

  @override
  State<TripInitializationScreen> createState() => _TripInitializationScreenState();
}

class _TripInitializationScreenState extends State<TripInitializationScreen> {
  final _vehicleController = TextEditingController(text: 'NB-4562');
  Map<String, dynamic>? _selectedRoute;
  bool _isInitializing = false;
  bool _loadingRoutes = true;
  List<Map<String, dynamic>> _routes = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() { _loadingRoutes = true; _loadError = null; });
    try {
      final response = await ApiService().getAllRoutes();
      if (response['success'] == true && response['routes'] != null) {
        final routes = List<Map<String, dynamic>>.from(response['routes']);
        setState(() {
          _routes = routes;
          _selectedRoute = routes.isNotEmpty ? routes[0] : null;
          _loadingRoutes = false;
        });
      } else {
        setState(() {
          _loadError = response['error'] ?? 'Failed to load routes';
          _loadingRoutes = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadError = 'Cannot connect to server';
        _loadingRoutes = false;
      });
    }
  }

  Future<void> _handleStartTrip() async {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route first'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_vehicleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a vehicle ID'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isInitializing = true);
    try {
      final response = await ApiService().initializeTrip(
        vehicleId: _vehicleController.text.trim(),
        routeId: _selectedRoute!['id'],
      );

      if (response['success'] == true) {
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
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
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
                      Navigator.pop(context);
                      try { await ApiService().logout(); } catch (_) {}
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
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

            // Vehicle ID input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle ID',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _vehicleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. NB-4562',
                      prefixIcon: const Icon(Icons.directions_bus,
                          color: Color(0xFF136AEC)),
                      filled: true,
                      fillColor: const Color(0xFFF6F7F8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E6F2))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E6F2))),
                    ),
                  ),
                ],
              ),
            ),

            // Route selector dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Route',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B))),
                  const SizedBox(height: 8),
                  if (_loadingRoutes)
                    const Center(child: CircularProgressIndicator())
                  else if (_loadError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_loadError!,
                                  style:
                                      TextStyle(color: Colors.red.shade700))),
                          TextButton(
                              onPressed: _loadRoutes,
                              child: const Text('Retry')),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E6F2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedRoute?['id'],
                          hint: const Text('Choose a route'),
                          items: _routes.map((route) {
                            return DropdownMenuItem<String>(
                              value: route['id'] as String,
                              child: Text(
                                'Route ${route['routeNumber']} — ${route['from']} to ${route['to']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            setState(() {
                              _selectedRoute = _routes
                                  .firstWhere((r) => r['id'] == id);
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),


            const SizedBox(height: 20),

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
