import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'mock_auth_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MockAuthService _mockAuth = MockAuthService();
  final ApiService _apiService = ApiService();
  
  // Flags to select auth backend
  bool _useMock = false;
  bool _useBackend = true;

  AuthService() {
    // ALWAYS use backend authentication
    // This ensures consistent authentication through the Node.js backend
    _useMock = false;
    _useBackend = true;
    debugPrint('🔌 Using Backend Authentication (via Node.js API)');
  }

  // Get current user
  User? get currentUser => _useMock ? null : _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => 
      _useMock ? Stream.value(null) : _firebaseAuth.authStateChanges();

  // Sign Up with Email and Password
  Future<dynamic> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      return await _mockAuth.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
    }

    if (_useBackend) {
      final data = await _apiService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Signup failed');
      }
      return data;
    }

    try {
      // Firebase path
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'uid': userCredential.user!.uid,
        'createdAt': DateTime.now(),
        'role': 'passenger',
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Use at least 6 characters.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email is already registered. Try logging in.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format.');
      }
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  // Login with Email and Password
  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      return await _mockAuth.login(email: email, password: password);
    }

    if (_useBackend) {
      final data = await _apiService.login(
        email: email,
        password: password,
      );
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Login failed');
      }
      return data;
    }

    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Try again.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format.');
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    if (_useMock) {
      return await _mockAuth.logout();
    }

    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    if (_useMock) {
      return await _mockAuth.getUserData(uid);
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
  }) async {
    if (_useMock) {
      return await _mockAuth.updateUserProfile(uid: uid, fullName: fullName);
    }

    try {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    if (_useMock) {
      return await _mockAuth.resetPassword(email);
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      }
      throw Exception('Failed to send reset email: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }
}
