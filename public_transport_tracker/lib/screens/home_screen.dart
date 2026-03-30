import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
import '../services/map_service.dart';
import '../services/notification_service.dart';
import '../services/geofencing_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  // Map and location tracking
  final MapController _mapController = MapController();
  final List<Marker> _busMarkers = [];
  final List<Marker> _userMarkers = [];
  LatLng? _userLocation;
  bool _isMapReady = false;

  // Real-time tracking
  final Map<String, LatLng> _liveBuses = {};
  StreamSubscription? _gpsSubscription;
  StreamSubscription? _userLocationSubscription;

  // Services
  final MapService _mapsService = MapService();
  final NotificationService _notificationService = NotificationService();
  final GeofencingService _geofencingService = GeofencingService();

  // Filter states
  String _selectedFilter = 'All';
  String _crowdFilter = 'All';

  // Default center (Galle, Sri Lanka)
  static const LatLng _defaultCenter = LatLng(6.0329, 80.2168);

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _connectToRealTimeUpdates();
    _startUserLocationTracking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gpsSubscription?.cancel();
    _userLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _notificationService.initialize();
      await _geofencingService.initialize();
      await _geofencingService.start();
      debugPrint('✅ All services initialized');
    } catch (e) {
      debugPrint('❌ Error initializing services: $e');
    }
  }

  void _connectToRealTimeUpdates() {
    SocketService().connect();
    _gpsSubscription = SocketService().gpsUpdates.listen((data) {
      if (!mounted) return;
      if (data['tripId'] != null && data['location'] != null) {
        final newPosition = LatLng(
          (data['location']['latitude'] as num).toDouble(),
          (data['location']['longitude'] as num).toDouble(),
        );
        setState(() {
          _liveBuses[data['tripId']] = newPosition;
          _updateBusMarkers();
        });
      }
    });
  }

  void _startUserLocationTracking() {
    _userLocationSubscription = _mapsService.getLocationUpdates().listen((location) {
      if (mounted) {
        setState(() {
          _userLocation = location;
          _updateUserMarker();
        });
      }
    });
  }

  void _updateBusMarkers() {
    _busMarkers.clear();
    for (final entry in _liveBuses.entries) {
      final busNumber = entry.key.contains('_') ? entry.key.split('_').last : entry.key;
      _busMarkers.add(
        _mapsService.createBusMarker(entry.value, busNumber: busNumber),
      );
    }
  }

  void _updateUserMarker() {
    if (_userLocation != null) {
      _userMarkers.clear();
      _userMarkers.add(_mapsService.createUserMarker(_userLocation!));
    }
  }

  void _showBusDetails(String tripId, String busNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    busNumber,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Live Tracking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/trip-tracking');
                },
                icon: const Icon(Icons.track_changes),
                label: const Text('Track This Bus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _setupNotificationForBus(tripId, busNumber);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.notifications),
                label: const Text('Notify When Near'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setupNotificationForBus(String tripId, String busNumber) async {
    if (_userLocation != null) {
      try {
        await _geofencingService.notifyWhenBusApproaches(
          tripId: tripId,
          busNumber: busNumber,
          stopLocation: _userLocation!,
          stopName: 'Your Location',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You\'ll be notified when Bus $busNumber approaches'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _centerOnUserLocation() async {
    final location = _userLocation ?? await _mapsService.getCurrentLocation();
    if (location != null && _isMapReady) {
      _mapController.move(location, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMarkers = [..._busMarkers, ..._userMarkers];

    return Stack(
      children: [
        // OpenStreetMap with real-time tracking
        SizedBox.expand(
          child: _mapsService.createMap(
            center: _userLocation ?? _defaultCenter,
            zoom: 13,
            markers: allMarkers,
            mapController: _mapController,
            onMapReady: () => setState(() => _isMapReady = true),
          ),
        ),

        // Top Header
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Icons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.account_circle, color: Color(0xFF0D131B), size: 24),
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications')),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.notifications, color: Color(0xFF0D131B), size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Color(0xFF4C6B9A)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Where to?',
                            hintStyle: TextStyle(color: Color(0xFF4C6B9A)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => Navigator.pushNamed(context, '/trip-planner'),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.mic, color: Color(0xFF136AEC)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Buttons Row
                Row(
                  children: [
                    _buildFilterButton('All', _selectedFilter == 'All',
                        () => setState(() => _selectedFilter = 'All')),
                    const SizedBox(width: 8),
                    _buildFilterButton('Bus', _selectedFilter == 'Bus',
                        () => setState(() => _selectedFilter = 'Bus')),
                    const SizedBox(width: 8),
                    _buildFilterButton('Train', _selectedFilter == 'Train',
                        () => setState(() => _selectedFilter = 'Train')),
                    const Spacer(),
                    _buildCrowdFilterButton(),
                  ],
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
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        border: const Border(bottom: BorderSide(color: Color(0xFFE0E6F2))),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF0D131B)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_isMapReady) {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.remove, color: Color(0xFF0D131B)),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _centerOnUserLocation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF136AEC)),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: -10),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    // Drag Handle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFD9E7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nearby Stops',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/routes'),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF136AEC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stop Group
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
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
                          const SizedBox(height: 12),
                          _buildBusStopItem('502', 'Galle - Hapugala', 'Many Seats Available', Colors.green, '3 min'),
                          const SizedBox(height: 8),
                          _buildBusStopItem('3', 'Galle - Matara', 'Few Seats', Colors.orange, '8 min'),
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

  Widget _buildBusStopItem(String number, String route, String crowd, Color crowdColor, String eta) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF136AEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D131B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: crowdColor),
                    const SizedBox(width: 4),
                    Text(crowd, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: crowdColor)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(eta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF136AEC))),
              const Text('ON TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF999CA6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF136AEC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF0D131B),
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdFilterButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['All', 'Available', 'Few Seats', 'Full'].map((level) {
              return ListTile(
                title: Text(level),
                trailing: _crowdFilter == level ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  setState(() => _crowdFilter = level);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people, size: 14, color: Color(0xFF0D131B)),
            const SizedBox(width: 4),
            Text(_crowdFilter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D131B))),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF0D131B)),
          ],
        ),
      ),
    );
  }
}
