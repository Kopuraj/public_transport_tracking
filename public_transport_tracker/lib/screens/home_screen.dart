import 'package:flutter/material.dart';
import 'dart:ui';
import 'routes_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedBottomNav = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      body: _getScreenForTab(_selectedBottomNav),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/test-navigator');
        },
        backgroundColor: Color(0xFF0066FF),
        icon: Icon(Icons.apps, color: Colors.white),
        label: Text('All Screens', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNav,
        onTap: (index) => setState(() => _selectedBottomNav = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF136AEC),
        unselectedItemColor: Color(0xFF999CA6),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getScreenForTab(int index) {
    switch (index) {
      case 0:
        return _buildMapScreen();
      case 1:
        return RoutesScreen();
      case 2:
        return TicketsScreen();
      case 3:
        return ProfileScreen();
      default:
        return _buildMapScreen();
    }
  }

  Widget _buildMapScreen() {
    return Stack(
      children: [
          // Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBXvcRTO5zuHfwfzjozH1RM5vdumfs_1pklscfvD27MS3bGuMncaZnvyMAOPJjRdCJHdHM_CRnEsIE7qkzxjzCpLyCTX0dVEuU1r4SUJGIqfSE5iybfDgzbEaKqxrnvbctHMtII8La1YE_BEp6sdo_s27CQmHu0XxAzNLlqidXVrIssxf9D45ck4Q3W0mj4A1lthn62tJa0KaGt3ioUaoe-lSXJt45fQXxu8wQ5K-zDP6VZFma4Rm-_7hwAVN-GO5r0J9g98CMSYAu8',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ),

          // Bus icons on map (simulated)
          Positioned(
            top: 200,
            left: 100,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.directions_bus, color: Colors.white, size: 20),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '502',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 120,
            right: 80,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.directions_bus, color: Colors.white, size: 20),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '502',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Profile and Notification Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Navigate to profile
                          setState(() => _selectedBottomNav = 3);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.account_circle, color: Color(0xFF0D131B), size: 24),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Notifications')),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.notifications, color: Color(0xFF0D131B), size: 24),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Search Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search, color: Color(0xFF4C6B9A)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Where to?',
                              hintStyle: TextStyle(color: Color(0xFF4C6B9A)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.mic, color: Color(0xFF136AEC)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Control Buttons (Right Side)
          Positioned(
            right: 16,
            top: 250,
            child: Column(
              spacing: 8,
              children: [
                Column(
                  spacing: 2,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Zoom In')),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                          border: Border(bottom: BorderSide(color: Color(0xFFE0E6F2))),
                        ),
                        child: Icon(Icons.add, color: Color(0xFF0D131B)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Zoom Out')),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.remove, color: Color(0xFF0D131B)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('My Location')),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.my_location, color: Color(0xFF136AEC)),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet - Nearby Stops
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        // Drag Handle
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Color(0xFFCFD9E7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Nearby Stops Header
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nearby Stops',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('See all stops')),
                                  );
                                },
                                child: Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF136AEC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stop Group 1
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Color(0xFF136AEC), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Galle Bus Stand',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF555D6E),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // Bus Item 1
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF6F7F8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFFE0E6F2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF136AEC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '502',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Galle - Hapugala',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D131B),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Many Seats Available',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '3 min',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF136AEC),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'ON TIME',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF999CA6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Stop Group 2
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Color(0xFF136AEC), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapugala Junction',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF555D6E),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // Bus Item 2
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF6F7F8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFFE0E6F2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[600],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '502',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Galle - Hapugala',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D131B),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Standing Room Only',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '12 min',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D131B),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'SLIGHT DELAY',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF999CA6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                border: Border(top: BorderSide(color: Color(0xFFE0E6F2))),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.map,
                        label: 'Map',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.route,
                        label: 'Routes',
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.confirmation_number,
                        label: 'Tickets',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.person,
                        label: 'Profile',
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildNavItem({
      required IconData icon,
      required String label,
      required int index,
    }) {
      bool isSelected = _selectedBottomNav == index;
      return GestureDetector(
        onTap: () => setState(() => _selectedBottomNav = index),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF136AEC) : Color(0xFF999CA6),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Color(0xFF136AEC) : Color(0xFF999CA6),
              ),
            ),
          ],
        ),
      );
    }
  }
