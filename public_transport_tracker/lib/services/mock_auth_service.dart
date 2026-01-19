import 'package:flutter/foundation.dart';

class MockUser {
  final String uid;
  final String email;
  final String fullName;

  MockUser({
    required this.uid,
    required this.email,
    required this.fullName,
  });
}

class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  // In-memory storage for demo users
  final Map<String, Map<String, dynamic>> _users = {};
  MockUser? _currentUser;

  MockUser? get currentUser => _currentUser;

  // Sign Up
  Future<MockUser?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if email already exists
    if (_users.containsKey(email)) {
      throw Exception('Email is already registered. Try logging in.');
    }

    // Validate email format
    if (!email.contains('@')) {
      throw Exception('Invalid email format.');
    }

    // Validate password length
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // Create user
    final uid = DateTime.now().millisecondsSinceEpoch.toString();
    _users[email] = {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'password': password,
      'createdAt': DateTime.now(),
      'role': 'passenger',
    };

    _currentUser = MockUser(uid: uid, email: email, fullName: fullName);
    debugPrint('✅ Mock SignUp successful: $email');
    return _currentUser;
  }

  // Login
  Future<MockUser?> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate email format
    if (!email.contains('@')) {
      throw Exception('Invalid email format.');
    }

    // Check if user exists
    if (!_users.containsKey(email)) {
      throw Exception('No account found with this email.');
    }

    // Check password
    if (_users[email]!['password'] != password) {
      throw Exception('Incorrect password. Try again.');
    }

    final userData = _users[email]!;
    _currentUser = MockUser(
      uid: userData['uid'],
      email: userData['email'],
      fullName: userData['fullName'],
    );

    debugPrint('✅ Mock Login successful: $email');
    return _currentUser;
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    debugPrint('✅ Mock Logout successful');
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    for (var userData in _users.values) {
      if (userData['uid'] == uid) {
        return Map<String, dynamic>.from(userData)..remove('password');
      }
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    for (var email in _users.keys) {
      if (_users[email]!['uid'] == uid) {
        _users[email]!['fullName'] = fullName;
        _users[email]!['updatedAt'] = DateTime.now();
        break;
      }
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (!_users.containsKey(email)) {
      throw Exception('No account found with this email.');
    }
    
    debugPrint('✅ Mock password reset email sent to: $email');
  }

  // Helper method to get all users (for debugging)
  Map<String, Map<String, dynamic>> getAllUsers() => Map.from(_users);
}
