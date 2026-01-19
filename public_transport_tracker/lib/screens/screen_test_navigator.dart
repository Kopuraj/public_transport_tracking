import 'package:flutter/material.dart';

class ScreenTestNavigator extends StatelessWidget {
  const ScreenTestNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Navigator - Test All Screens'),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '🧪 Screen Testing Tool',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap any button below to navigate to that screen',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Authentication Screens
          _buildSection('Authentication & Onboarding', [
            _buildNavButton(context, 'Welcome Screen', '/welcome'),
            _buildNavButton(context, 'Login Screen', '/login'),
            _buildNavButton(context, 'Sign Up Screen', '/signup'),
            _buildNavButton(context, 'Location Permission', '/location'),
          ]),

          // Main User Screens
          _buildSection('Main User Screens', [
            _buildNavButton(context, 'Home Screen', '/home'),
            _buildNavButton(context, 'Commuter Profile', '/commuter-profile'),
            _buildNavButton(context, 'Crowd Reporting', '/crowd-reporting'),
            _buildNavButton(context, 'Route Insights', '/route-insights'),
          ]),

          // Driver/Staff Screens
          _buildSection('Driver & Staff Screens', [
            _buildNavButton(context, 'Driver/Staff Login', '/driver-login'),
            _buildNavButton(context, 'Trip Initialization', '/trip-initialization'),
            _buildNavButton(context, 'Driver Trip Dashboard', '/driver-trip-dashboard'),
            _buildNavButton(context, 'Emergency Alert', '/emergency-alert'),
            _buildNavButton(context, 'Trip Summary', '/trip-summary'),
          ]),

          // Admin Screens
          _buildSection('Admin Screens', [
            _buildNavButton(context, 'Fleet Overview', '/admin-fleet'),
            _buildNavButton(context, 'Crowd Analytics', '/admin-crowd-analytics'),
            _buildNavButton(context, 'Emergency Broadcast', '/admin-broadcast'),
            _buildNavButton(context, 'Schedule Feedback', '/schedule-feedback'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0066FF),
            ),
          ),
        ),
        ...buttons,
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, String label, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          try {
            Navigator.pushNamed(context, route);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error navigating to $route: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
