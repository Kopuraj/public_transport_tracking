import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AdminFleetOverviewScreen extends StatefulWidget {
  const AdminFleetOverviewScreen({super.key});

  @override
  State<AdminFleetOverviewScreen> createState() => _AdminFleetOverviewScreenState();
}

class _AdminFleetOverviewScreenState extends State<AdminFleetOverviewScreen> {
  String _selectedTab = 'All Routes';
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _activeVehicles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActiveVehicles();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
  }

  Future<void> _loadActiveVehicles() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, this would load from the API
      // For demo, using static data with trip IDs
      _activeVehicles = [
        {
          'tripId': 'trip_123',
          'route': 'Galle - Colombo',
          'vehicle': 'NB-4562',
          'time': 'Eno 20 mins',
          'occupancy': '68%',
          'color': Colors.green,
          'status': 'active',
          'driverId': 'driver_001',
        },
        {
          'tripId': 'trip_124', 
          'route': 'Galle - Matara',
          'vehicle': 'NB-5623',
          'time': '15 mins Eta',
          'occupancy': '88%',
          'color': Colors.orange,
          'status': 'active',
          'driverId': 'driver_002',
        },
        {
          'tripId': 'trip_125',
          'route': 'Galle - Colombo',
          'vehicle': 'NB-3451',
          'time': 'En Route',
          'occupancy': '92%',
          'color': Colors.red,
          'status': 'active',
          'driverId': 'driver_003',
        },
      ];
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    } finally {
      setState(() => _isLoading = false);
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
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Color(0xFF0D131B)),
        ),
        title: Text(
          'Galle Fleet Overview',
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
              child: Icon(Icons.notifications, color: Color(0xFF136AEC)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Stats
            Container(
              padding: EdgeInsets.all(16),
              color: Color(0xFFF0F5FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('Active Vehicles', '42', Color(0xFF136AEC)),
                  _buildStatCard('Avg Occupancy', '68%', Colors.green),
                  _buildStatCard('Emergency', '2', Colors.red),
                ],
              ),
            ),

            // Tab Navigation
            Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All Routes',
                    'Delayed',
                    'Route 502',
                    'Route 3',
                  ].map((tab) {
                    bool isSelected = _selectedTab == tab;
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = tab),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF136AEC) : Color(0xFFF6F7F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Color(0xFF0D131B),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search vehicle or route...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999CA6),
                    ),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF999CA6)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Map Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(6.0329, 80.2168), // Galle, Sri Lanka
                      initialZoom: 12,
                      interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.public_transport_tracker',
                      ),
                      MarkerLayer(
                        markers: _activeVehicles.map((v) {
                          return Marker(
                            point: const LatLng(6.0329, 80.2168),
                            width: 28,
                            height: 28,
                            child: Icon(Icons.directions_bus,
                                color: v['color'] as Color, size: 22),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Active Vehicles Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Vehicles (42)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF136AEC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  ..._activeVehicles.map((vehicle) {
                    Color vehicleColor = vehicle['color'] as Color;
                    bool isActive = vehicle['status'] == 'active';
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? Color(0xFFF6F7F8) : Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? Color(0xFFE0E6F2) : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: vehicleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isActive ? Icons.directions_bus : Icons.cancel,
                                color: vehicleColor,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        vehicle['route'].toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D131B),
                                        ),
                                      ),
                                      if (!isActive) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'CANCELLED',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Bus ${vehicle['vehicle']} - ${vehicle['time']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF999CA6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: vehicleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  vehicle['occupancy'].toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: vehicleColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'cancel':
                                      _showCancelTripDialog(vehicle);
                                      break;
                                    case 'track':
                                      _trackVehicle(vehicle);
                                      break;
                                    case 'contact':
                                      _contactDriver(vehicle);
                                      break;
                                  }
                                },
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF999CA6),
                                  size: 18,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'track',
                                    child: Row(
                                      children: [
                                        Icon(Icons.track_changes, size: 16),
                                        SizedBox(width: 8),
                                        Text('Track Vehicle'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'contact',
                                    child: Row(
                                      children: [
                                        Icon(Icons.phone, size: 16),
                                        SizedBox(width: 8),
                                        Text('Contact Driver'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'cancel',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancel Trip', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'CANCELLED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelTripDialog(Map<String, dynamic> vehicle) async {
    String? cancellationReason;
    final reasons = [
      'Mechanical Issue',
      'Driver Unavailable', 
      'Route Blocked',
      'Weather Conditions',
      'Emergency',
      'Other'
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this trip?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Route: ${vehicle['route']}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              'Vehicle: ${vehicle['vehicle']}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Cancellation Reason:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              hint: Text('Select reason'),
              initialValue: cancellationReason,
              onChanged: (value) => cancellationReason = value,
              items: reasons.map((reason) => 
                DropdownMenuItem(value: reason, child: Text(reason))
              ).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            onPressed: () {
              if (cancellationReason != null) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a cancellation reason')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Trip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && cancellationReason != null) {
      await _cancelTrip(vehicle, cancellationReason!);
    }
  }

  Future<void> _cancelTrip(Map<String, dynamic> vehicle, String reason) async {
    setState(() => _isLoading = true);

    try {
      await _apiService.cancelTrip(vehicle['tripId'], reason);

      if (!mounted) return;
      setState(() => vehicle['status'] = 'cancelled');

      await _notificationService.showEmergencyAlert(
        title: 'Trip Cancelled',
        message: 'Trip ${vehicle['route']} (${vehicle['vehicle']}) has been cancelled due to $reason',
        route: vehicle['route'],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip cancelled successfully. Passengers have been notified.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadActiveVehicles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _trackVehicle(Map<String, dynamic> vehicle) {
    // Navigate to live tracking screen for this specific vehicle
    Navigator.pushNamed(
      context, 
      '/trip-tracking',
      arguments: {
        'tripId': vehicle['tripId'],
        'vehicleNumber': vehicle['vehicle'],
        'route': vehicle['route'],
      },
    );
  }

  void _contactDriver(Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Driver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Vehicle: ${vehicle['vehicle']}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Route: ${vehicle['route']}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // In real app, this would make a phone call
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling driver...')),
                      );
                    },
                    icon: Icon(Icons.phone),
                    label: Text('Call Driver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sending SMS...')),
                      );
                    },
                    icon: Icon(Icons.message),
                    label: Text('Send SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF999CA6),
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
