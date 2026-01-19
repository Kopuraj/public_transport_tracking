import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'screens/screen_test_navigator.dart';
import 'screens/backend_connectivity_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCMaSRN0-SOHUcFQ8Ctr43aS-hlixYBvs8',
        appId: '1:220609135478:android:a9e1a54c10196eadf07057',
        messagingSenderId: '220609135478',
        projectId: 'transit-live-pro',
        storageBucket: 'transit-live-pro.firebasestorage.app',
      ),
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization warning: $e');
    // App will fall back to backend authentication
  }
  
  runApp(const TransitLiveApp());
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
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/location': (context) => LocationPermissionScreen(),
        '/home': (context) => const HomeScreen(),
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
        '/test-navigator': (context) => const ScreenTestNavigator(),
        '/backend-check': (context) => const BackendConnectivityChecker(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Title
                Text(
                  'TransitLive Pro',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
                SizedBox(height: 10),
                // Tagline
                Text(
                  'Democratizing comfortable public transport.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 40),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LocationPermissionScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text('Get Started', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text('Sign In'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Version Info
                Text(
                  'v2.4.0 Live Network',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'All systems operational',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/test-navigator');
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.bug_report),
        label: const Text('Test Screens'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/backend-check');
            },
            icon: const Icon(Icons.cloud_queue),
            label: const Text('Check Backend Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}