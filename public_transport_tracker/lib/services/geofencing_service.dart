import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geofence_service/geofence_service.dart';
import 'notification_service.dart';
import 'socket_service.dart';
import 'dart:async';

class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  final GeofenceService _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: false,
    printDevLog: true,
  );

  final NotificationService _notificationService = NotificationService();
  final SocketService _socketService = SocketService();

  final Map<String, Geofence> _activeGeofences = {};
  final Map<String, Timer> _notificationTimers = {};
  bool _isInitialized = false;

  /// Initialize geofencing service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      geo.LocationPermission permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        throw Exception('Location permissions required for notifications');
      }

      await _notificationService.initialize();
      _setupGeofenceCallbacks();

      _isInitialized = true;
      debugPrint('✅ Geofencing service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing geofencing: $e');
      rethrow;
    }
  }

  /// Setup geofence event callbacks
  void _setupGeofenceCallbacks() {
    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.addLocationChangeListener(_onLocationChanged);
    _geofenceService.addLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
    _geofenceService.addActivityChangeListener(_onActivityChanged);
  }

  /// Handle geofence status changes
  Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    debugPrint('🔔 Geofence status changed: ${geofence.id} - $geofenceStatus');

    switch (geofenceStatus) {
      case GeofenceStatus.ENTER:
        _handleGeofenceEnter(geofence, location);
        break;
      case GeofenceStatus.EXIT:
        _handleGeofenceExit(geofence, location);
        break;
      case GeofenceStatus.DWELL:
        _handleGeofenceDwell(geofence, location);
        break;
    }
  }

  void _handleGeofenceEnter(Geofence geofence, Location location) {
    final data = geofence.data as Map<String, dynamic>? ?? {};
    final stopName = data['stopName'] as String? ?? 'Bus Stop';
    final busNumber = data['busNumber'] as String? ?? 'Unknown';
    final estimatedTime = data['estimatedTime'] as int? ?? 5;

    _notificationService.showBusArrivalNotification(
      busNumber: busNumber,
      stopName: stopName,
      estimatedMinutes: estimatedTime,
    );
  }

  void _handleGeofenceExit(Geofence geofence, Location location) {
    _notificationTimers[geofence.id]?.cancel();
    _notificationTimers.remove(geofence.id);
  }

  void _handleGeofenceDwell(Geofence geofence, Location location) {
    debugPrint('User dwelling near ${(geofence.data as Map?)?['stopName']}');
  }

  void _onLocationChanged(Location location) {
    debugPrint('📍 Location updated: ${location.latitude}, ${location.longitude}');
  }

  void _onLocationServicesStatusChanged(bool status) {
    debugPrint('📡 Location services: ${status ? 'enabled' : 'disabled'}');
  }

  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    debugPrint('🏃 Activity changed: ${prevActivity.type} -> ${currActivity.type}');
  }

  /// Set up notification for when bus approaches a stop
  Future<void> notifyWhenBusApproaches({
    required String tripId,
    required String busNumber,
    required dynamic stopLocation, // accepts LatLng from latlong2 or any with .latitude/.longitude
    required String stopName,
    double radiusMeters = 500.0,
    int estimatedArrivalMinutes = 5,
  }) async {
    if (!_isInitialized) {
      throw Exception('Geofencing service not initialized');
    }

    final geofenceId = '${tripId}_$stopName';

    final geofence = Geofence(
      id: geofenceId,
      latitude: (stopLocation.latitude as num).toDouble(),
      longitude: (stopLocation.longitude as num).toDouble(),
      radius: [
        GeofenceRadius(id: '${geofenceId}_radius', length: radiusMeters),
      ],
      data: {
        'tripId': tripId,
        'busNumber': busNumber,
        'stopName': stopName,
        'estimatedTime': estimatedArrivalMinutes,
        'type': 'bus_approach',
      },
    );

    _activeGeofences[geofenceId] = geofence;
    _geofenceService.addGeofence(geofence);

    debugPrint('📍 Monitoring bus approach for $busNumber at $stopName');
  }

  /// Set up geofence for user's destination
  Future<void> notifyWhenNearDestination({
    required dynamic destination, // accepts LatLng from latlong2
    required String destinationName,
    double radiusMeters = 300.0,
  }) async {
    if (!_isInitialized) {
      throw Exception('Geofencing service not initialized');
    }

    final geofenceId = 'destination_${destinationName.replaceAll(' ', '_')}';

    final geofence = Geofence(
      id: geofenceId,
      latitude: (destination.latitude as num).toDouble(),
      longitude: (destination.longitude as num).toDouble(),
      radius: [
        GeofenceRadius(id: '${geofenceId}_radius', length: radiusMeters),
      ],
      data: {
        'destinationName': destinationName,
        'type': 'destination_approach',
      },
    );

    _activeGeofences[geofenceId] = geofence;
    _geofenceService.addGeofence(geofence);
    debugPrint('📍 Monitoring approach to destination: $destinationName');
  }

  /// Monitor vehicle location and trigger proximity notifications
  Future<void> monitorVehicleApproach({
    required String tripId,
    required String busNumber,
    required dynamic userStop, // accepts LatLng from latlong2
    required String stopName,
  }) async {
    _socketService.connect();

    _socketService.gpsUpdates.listen((gpsData) {
      if (gpsData['tripId'] == tripId) {
        final busLat = (gpsData['location']['latitude'] as num).toDouble();
        final busLng = (gpsData['location']['longitude'] as num).toDouble();

        _checkVehicleProximity(
          busLat: busLat,
          busLng: busLng,
          stopLat: (userStop.latitude as num).toDouble(),
          stopLng: (userStop.longitude as num).toDouble(),
          busNumber: busNumber,
          stopName: stopName,
          tripId: tripId,
        );
      }
    });
  }

  void _checkVehicleProximity({
    required double busLat,
    required double busLng,
    required double stopLat,
    required double stopLng,
    required String busNumber,
    required String stopName,
    required String tripId,
  }) {
    final distance = geo.Geolocator.distanceBetween(busLat, busLng, stopLat, stopLng);

    if (distance <= 1000 && distance > 500) {
      _scheduleNotification(
        tripId: tripId,
        busNumber: busNumber,
        stopName: stopName,
        estimatedMinutes: (distance / 200).round(),
      );
    } else if (distance <= 500) {
      _notificationService.showBusArrivalNotification(
        busNumber: busNumber,
        stopName: stopName,
        estimatedMinutes: 2,
      );
    }
  }

  void _scheduleNotification({
    required String tripId,
    required String busNumber,
    required String stopName,
    required int estimatedMinutes,
  }) {
    final notificationId = '${tripId}_notification';
    if (_notificationTimers.containsKey(notificationId)) return;

    final delay = Duration(minutes: (estimatedMinutes - 2).clamp(0, estimatedMinutes));

    _notificationTimers[notificationId] = Timer(delay, () {
      _notificationService.showBusArrivalNotification(
        busNumber: busNumber,
        stopName: stopName,
        estimatedMinutes: 2,
      );
      _notificationTimers.remove(notificationId);
    });

    debugPrint('⏰ Scheduled notification for $busNumber in ${delay.inMinutes} minutes');
  }

  /// Clear all active geofences
  Future<void> clearAllGeofences() async {
    _geofenceService.clearGeofenceList();
    _activeGeofences.clear();

    for (final timer in _notificationTimers.values) {
      timer.cancel();
    }
    _notificationTimers.clear();

    debugPrint('🧹 Cleared all geofences and notifications');
  }

  /// Remove specific geofence by id
  Future<void> removeGeofence(String geofenceId) async {
    _geofenceService.removeGeofenceById(geofenceId);
    _activeGeofences.remove(geofenceId);

    _notificationTimers[geofenceId]?.cancel();
    _notificationTimers.remove(geofenceId);

    debugPrint('🗑️ Removed geofence: $geofenceId');
  }

  /// Start geofencing service
  Future<void> start() async {
    if (!_isInitialized) await initialize();
    await _geofenceService.start();
    debugPrint('▶️ Geofencing service started');
  }

  /// Stop geofencing service
  Future<void> stop() async {
    await _geofenceService.stop();
    await clearAllGeofences();
    debugPrint('⏹️ Geofencing service stopped');
  }

  bool get isRunning => _geofenceService.isRunningService;
  int get activeGeofencesCount => _activeGeofences.length;
}
