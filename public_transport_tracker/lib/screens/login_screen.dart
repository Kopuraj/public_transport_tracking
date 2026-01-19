import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login Function
  Future<void> _handleLogin() async {
    // Validate inputs
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call auth service to login
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Show success message
      _showSuccess('Login successful!');

      // Navigate to home screen after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F9FC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, color: Color(0xFF0066FF), size: 28),
            SizedBox(width: 8),
            Text(
              'TransitLive Pro',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to track your next ride',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF456AA1),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Email Field
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'e.g. name@email.com',
                  hintStyle: TextStyle(color: Color(0xFF456AA1)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFCDD8EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFCDD8EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF0066FF), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.mail, color: Color(0xFF456AA1)),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Password Field
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Color(0xFF456AA1)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFCDD8EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFCDD8EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF0066FF), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword ? Icons.lock : Icons.lock_open,
                        color: Color(0xFF456AA1),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _isLoading ? null : () {
                    // Handle forgot password
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Forgot password - coming soon')),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0066FF),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0066FF),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Color(0xFF0066FF).withValues(alpha: 0.3),
                    disabledBackgroundColor: Color(0xFF0066FF).withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),

              // Divider with OR text
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Color(0xFFCDD8EA)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF456AA1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Color(0xFFCDD8EA)),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Social Login Buttons
              Row(
                children: [
                  // Google Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google login coming soon')),
                        );
                      },
                      icon: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBRdgubqNfYEeT6C-MpFUjKZUBJwiChwiugANqVlnXntNllzAKtyDrxVyg5UaZ9uuZVsOf9E4PkJ2JBXHkTt30Z8fhSM_iQan6LPpXoI7IUlLaCWj8ml-cdzupVkyqdrOFAvkRd5T3SRnGFtQsDZKU87SurXNrlEU8exKIAyYZf2jn592kRRL5l-vwi6p3uMh8XDn_aXFXpmK_Xxr5_ADjap0YY35H6ICo4PwYS29ovr1fhOIa2PmDOrxi0a2KmK43kFTnwF8kzOWrD',
                        width: 20,
                        height: 20,
                      ),
                      label: Text('Google'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Color(0xFFCDD8EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Apple Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Apple login coming soon')),
                        );
                      },
                      icon: Icon(Icons.apple, size: 20),
                      label: Text('Apple'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Color(0xFFCDD8EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Sign Up Link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'New here? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF456AA1),
                    ),
                    children: [
                      TextSpan(
                        text: 'Create an account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066FF),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
