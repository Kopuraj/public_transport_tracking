import 'package:flutter/material.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'My Tickets',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 64,
                  color: Color(0xFF136AEC),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No tickets yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D131B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Browse available routes and track live buses.\nTicket booking will be added soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999CA6),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/routes'),
                  icon: const Icon(Icons.route),
                  label: const Text('Browse Routes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF136AEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
