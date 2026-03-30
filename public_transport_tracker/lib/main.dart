import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/location_permission_screen.dart';
import 'screens/home_screen.dart';
import 'screens/crowd_reporting_screen.dart';
import 'screens/commuter_profile_screen.dart';
import 'screens/route_insights_screen.dart';
import 'screens/driver_staff_login_screen.dart';
import 'screens/trip_initialization_screen.dart';
import 'screens/driver_trip_dashboard_screen.dart';
import 'screens/staff_emergency_alert_screen.dart';
import 'screens/trip_summary_screen.dart';
import 'screens/admin_fleet_overview_screen.dart';
import 'screens/admin_crowd_analytics_screen.dart';
import 'screens/admin_emergency_broadcast_screen.dart';
import 'screens/schedule_feedback_screen.dart';
import 'screens/routes_screen.dart';
import 'screens/trip_tracking_screen.dart';
import 'screens/trip_planner_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'screens/simple_map_test_screen.dart';
import 'screens/basic_location_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/geofencing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCAQJ1aUoltX6D1uys_kb44uT835prFpig',
        appId: '1:562185660729:web:79fd7c568a1de3a27a589d',
        messagingSenderId: '562185660729',
        projectId: 'transitlive-pro',
        storageBucket: 'transitlive-pro.firebasestorage.app',
      ),
    );
    debugPrint('✅ Firebase initialized successfully');
    
    // Initialize core services
    await _initializeServices();
    
  } catch (e) {
    debugPrint('⚠️ Firebase initialization warning: $e');
    // App will fall back to backend authentication
  }
  
  runApp(const TransitLiveApp());
}

/// Initialize all core services
Future<void> _initializeServices() async {
  try {
    // Initialize notification service (skip on web — uses native platform APIs)
    if (!kIsWeb) {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('✅ Notification service initialized');
    }

    // Initialize geofencing service (skip on web — requires native GPS)
    if (!kIsWeb) {
      final geofencingService = GeofencingService();
      await geofencingService.initialize();
      debugPrint('✅ Geofencing service initialized');
    }

    // Setup token refresh mechanism
    _setupTokenRefresh();

  } catch (e) {
    debugPrint('⚠️ Service initialization error: $e');
    // Continue with app initialization even if some services fail
  }
}

/// Setup automatic token refresh
void _setupTokenRefresh() {
  // Check and refresh token every 30 minutes
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    try {
      final apiService = ApiService();
      final token = await apiService.getStoredToken();
      
      if (token != null) {
        // Test token validity
        try {
          await apiService.checkBackendHealth();
          debugPrint('🔄 Token is still valid');
        } catch (e) {
          // Token might be expired, attempt to refresh or logout
          debugPrint('🔄 Token validation failed, may need refresh: $e');
          // In a production app, implement token refresh logic here
        }
      }
    } catch (e) {
      debugPrint('❌ Token refresh check error: $e');
    }
  });
}

class TransitLiveApp extends StatelessWidget {
  const TransitLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransitLive Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Color(0xFFF5F5F8),
      ),
      home: const AuthGuard(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthGuard(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/location': (context) => LocationPermissionScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/routes': (context) => const RoutesScreen(),
        '/trip-tracking': (context) => const TripTrackingScreen(),
        '/trip-planner': (context) => const TripPlannerScreen(),
        '/tickets': (context) => const TicketsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/crowd-reporting': (context) => const CrowdReportingScreen(),
        '/commuter-profile': (context) => const CommuterProfileScreen(),
        '/route-insights': (context) => const RouteInsightsScreen(),
        '/driver-login': (context) => const DriverStaffLoginScreen(),
        '/trip-initialization': (context) => const TripInitializationScreen(),
        '/driver-trip-dashboard': (context) => const DriverTripDashboardScreen(),
        '/emergency-alert': (context) => const StaffEmergencyAlertScreen(),
        '/trip-summary': (context) => const TripSummaryScreen(),
        '/admin-fleet': (context) => const AdminFleetOverviewScreen(),
        '/admin-crowd-analytics': (context) => const AdminCrowdAnalyticsScreen(),
        '/admin-broadcast': (context) => const AdminEmergencyBroadcastScreen(),
        '/schedule-feedback': (context) => const ScheduleFeedbackScreen(),
      },
    );
  }
}

// Authentication Guard - checks if user is logged in
class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final apiService = ApiService();
      final token = await apiService.getStoredToken();
      setState(() {
        _isLoggedIn = token != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading TransitLive Pro...'),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return const MainNavigationScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}

// Welcome Screen for new users
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                  ),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // Title
              const Text(
                'TransitLive Pro',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066FF),
                ),
              ),
              const SizedBox(height: 10),
              // Tagline
              const Text(
                'Real-time public transport tracking\nfor smarter commuting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              // Features
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeature(Icons.location_on, 'Live GPS'),
                  _buildFeature(Icons.people, 'Crowd Info'),
                  _buildFeature(Icons.schedule, 'Real ETAs'),
                ],
              ),
              const SizedBox(height: 50),
              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'All systems operational',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Main Navigation Screen with bottom navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const RoutesScreen(),
    const TripTrackingScreen(),
    const TicketsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}