import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  
  // Controllers to expose streams of data
  final StreamController<Map<String, dynamic>> _gpsUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _crowdUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _tripStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _tripEndedController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams for UI consumption
  Stream<Map<String, dynamic>> get gpsUpdates => _gpsUpdateController.stream;
  Stream<Map<String, dynamic>> get crowdUpdates => _crowdUpdateController.stream;
  Stream<Map<String, dynamic>> get tripStarted => _tripStartedController.stream;
  Stream<Map<String, dynamic>> get tripEnded => _tripEndedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    debugPrint('🔌 Connecting to WebSocket at ${ApiConfig.wsUrl}');
    
    _socket = IO.io(ApiConfig.wsUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // Use WebSocket only
      .setReconnectionAttempts(5)
      .setReconnectionDelay(2000)
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('✅ Connected to WebSocket');
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Disconnected from WebSocket');
    });

    _socket!.onConnectError((data) {
      debugPrint('⚠️ Connection Error: $data');
    });

    // Listen for events from the server
    _socket!.on('gps-update', (data) {
      debugPrint('📍 Received GPS update: $data');
      _gpsUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('crowd-update', (data) {
      debugPrint('👥 Received Crowd update: $data');
      _crowdUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('trip-started', (data) {
      debugPrint('🏁 Trip started: $data');
      _tripStartedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('trip-ended', (data) {
      debugPrint('🛑 Trip ended: $data');
      _tripEndedController.add(Map<String, dynamic>.from(data));
    });
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _gpsUpdateController.close();
    _crowdUpdateController.close();
    _tripStartedController.close();
    _tripEndedController.close();
    disconnect();
  }
}
