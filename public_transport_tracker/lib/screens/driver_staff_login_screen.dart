import 'package:flutter/material.dart';

class DriverStaffLoginScreen extends StatefulWidget {
  const DriverStaffLoginScreen({super.key});

  @override
  State<DriverStaffLoginScreen> createState() => _DriverStaffLoginScreenState();
}

class _DriverStaffLoginScreenState extends State<DriverStaffLoginScreen> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_employeeIdController.text.isEmpty) {
      _showError('Please enter your Employee ID');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccess('Login successful!');
      
      // Navigate to trip initialization after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/trip-initialization');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1F3A),
                Color(0xFF0D131B),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF136AEC).withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.business,
                    size: 60,
                    color: Color(0xFF136AEC),
                  ),
                ),
                SizedBox(height: 24),

                // Title
                Text(
                  'Staff Portal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),

                // Subtitle
                Text(
                  'TransitLive Pro',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999CA6),
                  ),
                ),
                SizedBox(height: 12),

                Text(
                  'Galle Transport Services',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999CA6),
                  ),
                ),
                SizedBox(height: 40),

                // Employee ID Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMPLOYEE ID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF999CA6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1F2536),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF2A3147)),
                      ),
                      child: TextField(
                        controller: _employeeIdController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter 6-digit ID',
                          hintStyle: TextStyle(color: Color(0xFF666B77)),
                          prefixIcon: Icon(Icons.badge, color: Color(0xFF666B77)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSWORD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF999CA6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1F2536),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF2A3147)),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Color(0xFF666B77)),
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF666B77)),
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _isPasswordVisible = !_isPasswordVisible),
                            child: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Color(0xFF666B77),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password recovery feature coming soon')),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF136AEC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF136AEC),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Color(0xFF136AEC).withValues(alpha: 0.5),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Login to Duty',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 24),

                // Info Box
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1F2536),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF2A3147)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Color(0xFF136AEC), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Having trouble logging in?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF999CA6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📞 Contact Transport Authority'),
                            ),
                          );
                        },
                        child: Text(
                          '☎ Contact Transport Authority',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF136AEC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Security Notice
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      top: BorderSide(color: Color(0xFF2A3147), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.security, color: Color(0xFF666B77), size: 18),
                      SizedBox(height: 8),
                      Text(
                        'OFFICIAL USE ONLY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666B77),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Access to transport management system is restricted and monitored',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          color: Color(0xFF555D6E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
