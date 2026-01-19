import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api';
  // For real device testing, use your machine IP:
  // static const String baseUrl = 'http://192.168.x.x:5000/api';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();

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

  // ============================================
  // AUTHENTICATION ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'passenger',
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
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['token'] != null) {
          await _saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Signup failed');
      }
    } catch (e) {
      debugPrint('SignUp Error: $e');
      throw Exception('Network error: $e');
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['token'] != null) {
          await _saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  // ============================================
  // TRIP MANAGEMENT ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> initializeTrip({
    required String driverId,
    required String vehicleId,
    required String routeId,
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
          'driverId': driverId,
          'vehicleId': vehicleId,
          'routeId': routeId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Trip initialization failed');
      }
    } catch (e) {
      debugPrint('Initialize Trip Error: $e');
      throw Exception('Failed to initialize trip: $e');
    }
  }

  Future<Map<String, dynamic>> sendGpsUpdate({
    required String tripId,
    required double latitude,
    required double longitude,
    double? speed,
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
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('GPS update failed');
      }
    } catch (e) {
      debugPrint('GPS Update Error: $e');
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
      debugPrint('Get Trip Error: $e');
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
      debugPrint('End Trip Error: $e');
      throw Exception('Failed to end trip: $e');
    }
  }

  // ============================================
  // CROWD REPORTING ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> submitCrowdReport({
    required String tripId,
    required String crowdLevel, // 'low', 'medium', 'high'
    required double latitude,
    required double longitude,
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
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Report submission failed');
      }
    } catch (e) {
      debugPrint('Crowd Report Error: $e');
      throw Exception('Failed to submit crowd report: $e');
    }
  }

  // ============================================
  // ROUTE SEARCH ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> searchRoute({
    required String startPoint,
    required String endPoint,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/route/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startPoint': startPoint,
          'endPoint': endPoint,
          'currentLocation': {
            'latitude': latitude ?? 0,
            'longitude': longitude ?? 0,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Route search failed');
      }
    } catch (e) {
      debugPrint('Route Search Error: $e');
      throw Exception('Failed to search routes: $e');
    }
  }

  // ============================================
  // ALERT ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String tripId,
    required String alertType, // 'breakdown', 'accident', 'medical'
    required String description,
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
          'description': description,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Emergency alert failed');
      }
    } catch (e) {
      debugPrint('Emergency Alert Error: $e');
      throw Exception('Failed to send emergency alert: $e');
    }
  }

  // ============================================
  // ADMIN ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getRouteAnalytics(String routeId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/analytics/$routeId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Not authorized to view analytics');
      } else {
        throw Exception('Failed to fetch analytics');
      }
    } catch (e) {
      debugPrint('Analytics Error: $e');
      throw Exception('Failed to get analytics: $e');
    }
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health Check Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getBackendStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get status');
    } catch (e) {
      debugPrint('Status Check Error: $e');
      throw Exception('Backend unreachable: $e');
    }
  }
}
