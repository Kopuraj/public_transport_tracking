import 'package:flutter/material.dart';

class AdminFleetOverviewScreen extends StatefulWidget {
  const AdminFleetOverviewScreen({super.key});

  @override
  State<AdminFleetOverviewScreen> createState() => _AdminFleetOverviewScreenState();
}

class _AdminFleetOverviewScreenState extends State<AdminFleetOverviewScreen> {
  String _selectedTab = 'All Routes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Color(0xFF0D131B)),
        ),
        title: Text(
          'Galle Fleet Overview',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Icon(Icons.notifications, color: Color(0xFF136AEC)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Stats
            Container(
              padding: EdgeInsets.all(16),
              color: Color(0xFFF0F5FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('Active Vehicles', '42', Color(0xFF136AEC)),
                  _buildStatCard('Avg Occupancy', '68%', Colors.green),
                  _buildStatCard('Emergency', '2', Colors.red),
                ],
              ),
            ),

            // Tab Navigation
            Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All Routes',
                    'Delayed',
                    'Route 502',
                    'Route 3',
                  ].map((tab) {
                    bool isSelected = _selectedTab == tab;
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = tab),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF136AEC) : Color(0xFFF6F7F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Color(0xFF0D131B),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search vehicle or route...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999CA6),
                    ),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF999CA6)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Map Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/-74.0,40.7,12,0,0/400x300@2x?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycW1vNHprM3JzbDgifQ.rJcFIG214AriISLbB6B5aw',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Icon(Icons.layers, color: Color(0xFF136AEC), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Active Vehicles Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Vehicles (42)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF136AEC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...[
                    {
                      'route': 'Galle - Colombo',
                      'vehicle': 'NB-4562',
                      'time': 'Eno 20 mins',
                      'occupancy': '68%',
                      'color': Colors.green,
                    },
                    {
                      'route': 'Galle - Matara',
                      'vehicle': 'NB-5623',
                      'time': '15 mins Eta',
                      'occupancy': '88%',
                      'color': Colors.orange,
                    },
                    {
                      'route': 'Galle - Colombo',
                      'vehicle': 'NB-3451',
                      'time': 'En Route',
                      'occupancy': '92%',
                      'color': Colors.red,
                    },
                  ].map((vehicle) {
                    Color vehicleColor = vehicle['color'] as Color;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF6F7F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFE0E6F2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: vehicleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.directions_bus,
                                color: vehicleColor,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle['route'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D131B),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Bus ${vehicle['vehicle']} - ${vehicle['time']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF999CA6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vehicleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vehicle['occupancy'].toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: vehicleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF999CA6),
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
