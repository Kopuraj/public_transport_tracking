import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      _initialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android (not on web)
    if (!kIsWeb) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for different types of notifications
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'bus_arrival',
        'Bus Arrival Alerts',
        description: 'Notifications when your bus is approaching',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      AndroidNotificationChannel(
        'crowd_alerts',
        'Crowd Level Alerts',
        description: 'Notifications about bus crowding levels',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'delay_alerts',
        'Delay Notifications',
        description: 'Notifications about bus delays and cancellations',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'emergency_alerts',
        'Emergency Alerts',
        description: 'Important emergency and safety alerts',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('emergency_sound'),
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    await requestPermission();
    
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToPreferences(token);
      debugPrint('📱 FCM Token: $token');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToPreferences(newToken);
      debugPrint('🔄 FCM Token refreshed: $newToken');
    });
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle messages when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Handle messages when app is terminated
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle messages when app is opened from notification
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Background message: ${message.messageId}');
    
    // Handle navigation based on message data
    _handleNotificationNavigation(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'bus_arrival':
        // Navigate to trip tracking screen
        break;
      case 'delay_alert':
        // Navigate to route details
        break;
      case 'emergency_alert':
        // Show emergency alert dialog
        break;
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Request notification permission
  Future<NotificationSettings> requestPermission() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Save token to preferences for backend registration
  Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Get saved token from preferences
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// Subscribe to topic for broadcast messages
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('📬 Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('📪 Unsubscribed from topic: $topic');
  }

  // SPECIFIC NOTIFICATION METHODS FOR YOUR TRANSPORT APP

  /// Show bus arrival notification
  Future<void> showBusArrivalNotification({
    required String busNumber,
    required String stopName,
    required int estimatedMinutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bus_arrival',
      'Bus Arrival Alerts',
      channelDescription: 'Notifications when your bus is approaching',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/bus_icon',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Bus $busNumber Approaching',
      body: 'Arriving at $stopName in $estimatedMinutes minutes',
      notificationDetails: details,
      payload: 'bus_arrival:$busNumber',
    );
  }

  /// Show crowd level alert
  Future<void> showCrowdAlert({
    required String busNumber,
    required String crowdLevel,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'crowd_alerts',
      'Crowd Level Alerts',
      importance: Importance.defaultImportance,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final message = crowdLevel == 'full'
        ? 'Bus $busNumber is overcrowded. Consider waiting for the next bus.'
        : 'Bus $busNumber crowd level: $crowdLevel';

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Crowd Update',
      body: message,
      notificationDetails: details,
      payload: 'crowd_alert:$busNumber',
    );
  }

  /// Show delay notification
  Future<void> showDelayNotification({
    required String busNumber,
    required int delayMinutes,
    String? reason,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'delay_alerts',
      'Delay Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final message = reason != null
        ? 'Bus $busNumber is delayed by $delayMinutes minutes due to $reason'
        : 'Bus $busNumber is delayed by $delayMinutes minutes';

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Service Delay',
      body: message,
      notificationDetails: details,
      payload: 'delay:$busNumber',
    );
  }

  /// Show emergency alert
  Future<void> showEmergencyAlert({
    required String title,
    required String message,
    String? route,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_alerts',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '🚨 $title',
      body: message,
      notificationDetails: details,
      payload: 'emergency:${route ?? 'all'}',
    );
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id: id);
  }
}

/// Background message handler (top-level function required)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message: ${message.messageId}');
}