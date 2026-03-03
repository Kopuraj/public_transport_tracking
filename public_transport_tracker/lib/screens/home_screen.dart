import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/socket_service.dart';
import '../services/map_service.dart';
import 'routes_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedBottomNav = 0;
  
  // Real-time tracking for all buses
  final Map<String, LatLng> _liveBuses = {};
  StreamSubscription? _gpsSubscription;
  final MapController _mapController = MapController();
  bool _isMapReady = false; // Add this

  @override
  void initState() {
    super.initState();
    _connectToRealTimeUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  void _connectToRealTimeUpdates() {
    SocketService().connect();
    _gpsSubscription = SocketService().gpsUpdates.listen((data) {
      if (!mounted) return;
      if (data['tripId'] != null && data['location'] != null) {
        setState(() {
          _liveBuses[data['tripId']] = LatLng(
            data['location']['latitude'],
            data['location']['longitude'],
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = _liveBuses.entries.map((entry) {
      return MapService().createBusMarker(
        entry.value,
        busNumber: entry.key.contains('_') ? entry.key.split('_').last : entry.key,
      );
    }).toList();

    return Stack(
      children: [
        // Real Dynamic Map
        SizedBox.expand(
          child: MapService().createMap(
            center: const LatLng(6.0329, 80.2168), // Default to Galle
            zoom: 13,
            mapController: _mapController,
            onMapReady: () {
              setState(() => _isMapReady = true);
              debugPrint('🗺️ Home Map Ready');
            },
            markers: markers,
          ),
        ),
        
        // Transparent overlay for some depth
        IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),

        // Top Header
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Profile and Notification Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // The parent Navigator handles this now
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.account_circle, color: Color(0xFF0D131B), size: 24),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Notifications')),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.notifications, color: Color(0xFF0D131B), size: 24),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Color(0xFF4C6B9A)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Where to?',
                            hintStyle: TextStyle(color: Color(0xFF4C6B9A)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.mic, color: Color(0xFF136AEC)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Map Control Buttons (Right Side)
        Positioned(
          right: 16,
          top: 220,
          child: Column(
            spacing: 8,
            children: [
              Column(
                spacing: 2,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isMapReady) {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                        border: Border(bottom: BorderSide(color: Color(0xFFE0E6F2))),
                      ),
                      child: Icon(Icons.add, color: Color(0xFF0D131B)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_isMapReady) {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.remove, color: Color(0xFF0D131B)),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Re-center on default or user location
                  if (_isMapReady) {
                    _mapController.move(const LatLng(6.0329, 80.2168), 13);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.my_location, color: Color(0xFF136AEC)),
                ),
              ),
            ],
          ),
        ),

        // Bottom Sheet - Nearby Stops
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.15,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    // Drag Handle
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFFCFD9E7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Nearby Stops Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Stops',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF136AEC),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stop Group 1
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF136AEC), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Galle Bus Stand',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555D6E),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // Bus Item 1
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF6F7F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFE0E6F2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF136AEC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '502',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Galle - Hapugala',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D131B),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.green,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Many Seats Available',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '3 min',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF136AEC),
                                      ),
                                    ),
                                    Text(
                                      'ON TIME',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF999CA6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
