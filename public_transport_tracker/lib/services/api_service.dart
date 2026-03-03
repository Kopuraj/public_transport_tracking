import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = 'http://192.168.1.130:5000/api';
  static const String wsUrl = 'ws://192.168.1.130:5000';
  // For local testing:
  // static const String baseUrl = 'http://localhost:5000/api';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();

  // ============================================
  // TOKEN MANAGEMENT
  // ============================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  // Public method to access stored token
  Future<String?> getStoredToken() async {
    return await _getToken();
  }

  // Public method to access stored role
  Future<String?> getStoredRole() async {
    return await _getUserRole();
  }

  // ============================================
  // 1. AUTHENTICATION ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'passenger',
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['token'] != null) {
          await _saveToken(data['token']);
          if (data['user']['uid'] != null) {
            await _saveUserId(data['user']['uid']);
          }
          if (data['user']['role'] != null) {
            await _saveUserRole(data['user']['role']);
          }
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Signup failed');
      }
    } catch (e) {
      debugPrint('❌ SignUp Error: $e');
      throw Exception('Signup error: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['token'] != null) {
          await _saveToken(data['token']);
          if (data['user']['uid'] != null) {
            await _saveUserId(data['user']['uid']);
          }
          if (data['user']['role'] != null) {
            await _saveUserRole(data['user']['role']);
          }
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('❌ Login Error: $e');
      throw Exception('Login error: $e');
    }
  }

  Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_role');
    }
  }

  // ============================================
  // 2. ROUTES ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getAllRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/routes'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch routes');
      }
    } catch (e) {
      debugPrint('❌ Get Routes Error: $e');
      throw Exception('Failed to fetch routes: $e');
    }
  }

  Future<Map<String, dynamic>> getRoute(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/routes/$routeId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Route not found');
      }
    } catch (e) {
      debugPrint('❌ Get Route Error: $e');
      throw Exception('Failed to fetch route: $e');
    }
  }

  Future<Map<String, dynamic>> getActiveTripsOnRoute(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/routes/$routeId/active-trips'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch active trips');
      }
    } catch (e) {
      debugPrint('❌ Get Active Trips Error: $e');
      throw Exception('Failed to fetch active trips: $e');
    }
  }

  // ============================================
  // 3. TRIP MANAGEMENT ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> initializeTrip({
    required String vehicleId,
    required String routeId,
    String? conductorId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/trips/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehicleId': vehicleId,
          'routeId': routeId,
          'conductorId': conductorId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Trip initialization failed');
      }
    } catch (e) {
      debugPrint('❌ Initialize Trip Error: $e');
      throw Exception('Failed to initialize trip: $e');
    }
  }

  Future<Map<String, dynamic>> sendGpsUpdate({
    required String tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/gps'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed ?? 0,
          'accuracy': accuracy,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('GPS update failed');
      }
    } catch (e) {
      debugPrint('❌ GPS Update Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTripDetails(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trips/$tripId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch trip details');
      }
    } catch (e) {
      debugPrint('❌ Get Trip Error: $e');
      throw Exception('Failed to get trip: $e');
    }
  }

  Future<Map<String, dynamic>> endTrip(String tripId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to end trip');
      }
    } catch (e) {
      debugPrint('❌ End Trip Error: $e');
      throw Exception('Failed to end trip: $e');
    }
  }

  // ============================================
  // 4. CROWD INTELLIGENCE ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> submitCrowdReport({
    required String tripId,
    required String crowdLevel,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reports/crowd'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tripId': tripId,
          'crowdLevel': crowdLevel,
          'userLocation': {
            'latitude': userLatitude,
            'longitude': userLongitude,
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to submit crowd report');
      }
    } catch (e) {
      debugPrint('❌ Crowd Report Error: $e');
      throw Exception('Failed to submit crowd report: $e');
    }
  }

  Future<Map<String, dynamic>> getCrowdReports(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/crowd-reports'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch crowd reports');
      }
    } catch (e) {
      debugPrint('❌ Get Crowd Reports Error: $e');
      throw Exception('Failed to fetch crowd reports: $e');
    }
  }

  // ============================================
  // 5. EMERGENCY ALERTS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String tripId,
    required String alertType,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/alerts/emergency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tripId': tripId,
          'alertType': alertType,
          'message': message,
          'location': latitude != null && longitude != null ? {
            'latitude': latitude,
            'longitude': longitude,
          } : null,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send emergency alert');
      }
    } catch (e) {
      debugPrint('❌ Emergency Alert Error: $e');
      throw Exception('Failed to send emergency alert: $e');
    }
  }

  Future<Map<String, dynamic>> resolveAlert(String alertId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/alerts/$alertId/resolve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to resolve alert');
      }
    } catch (e) {
      debugPrint('❌ Resolve Alert Error: $e');
      throw Exception('Failed to resolve alert: $e');
    }
  }

  // ============================================
  // 6. SEARCH & ROUTE INSIGHTS
  // ============================================

  Future<Map<String, dynamic>> searchRoutes({
    required String startStop,
    required String endStop,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/search/routes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startStop': startStop,
          'endStop': endStop,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Route search failed');
      }
    } catch (e) {
      debugPrint('❌ Route Search Error: $e');
      throw Exception('Failed to search routes: $e');
    }
  }

  Future<Map<String, dynamic>> getRouteInsights(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/routes/$routeId/insights'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch route insights');
      }
    } catch (e) {
      debugPrint('❌ Route Insights Error: $e');
      throw Exception('Failed to fetch route insights: $e');
    }
  }

  // ============================================
  // 7. USER PROFILE ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      debugPrint('❌ Get Profile Error: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/$userId/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'preferences': preferences,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      debugPrint('❌ Update Profile Error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // ============================================
  // 8. ADMIN ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Access denied');
      }
    } catch (e) {
      debugPrint('❌ Admin Dashboard Error: $e');
      throw Exception('Failed to fetch admin dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> getRouteAnalytics() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/analytics/routes'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Access denied');
      }
    } catch (e) {
      debugPrint('❌ Route Analytics Error: $e');
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  // ============================================
  // 9. HEALTH CHECK ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'status': 'unhealthy'};
      }
    } catch (e) {
      debugPrint('❌ Health Check Error: $e');
      return {'success': false, 'status': 'unreachable', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBackendStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/status'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch status');
      }
    } catch (e) {
      debugPrint('❌ Status Check Error: $e');
      throw Exception('Failed to check status: $e');
    }
  }
}
