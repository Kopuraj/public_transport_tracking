import 'package:flutter/material.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F7F8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF0066FF), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TransitLive Pro',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 16),

              // Map Illustration Container with Pulsing Pin
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAg16I2Ch6lETLA4LHgX2BQ3YQzekl6ju8p_aab7-7EVYG2-xvpk4q3hyO9TmtYym8MwL4wL2OZcXsF0g1-XB8yKsSFsUOKrNWUNz7ePDUvOlLzMI2o-oci1i9Q7pBidzJJKlQ_GFfZok84CaYjJv5_z1eY4cVqba59cAHthO8RPO3X13Y5srk_t_oMzloa0l_aOUBgC8ly7G6sLYw2Dpzh4nPQfaU1icTSgPmhpHHAm6W4DXVBNzCwU2HZMioR3ODh34h1X1AMdbpx',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    // Pulsing location pin
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0066FF),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF0066FF).withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Headline
              Text(
                'Find Your Way',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Enable location services to see buses nearby, get live ETAs for your stop, and receive alerts for your route.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF717E95),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),

              // Privacy Trust Indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF0066FF).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Color(0xFF0066FF), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'YOUR PRIVACY IS PROTECTED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0066FF),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Allow Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location permission granted')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0066FF),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Color(0xFF0066FF).withValues(alpha: 0.3),
                  ),
                  child: Text(
                    'Allow Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Enter Location Manually Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enter location manually')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE8EAED),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Enter Location Manually',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Privacy Policy Footer
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'You can change this anytime in your phone\'s settings. By allowing, you agree to our ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // iOS Style Bottom Indicator
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFCDD8EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
