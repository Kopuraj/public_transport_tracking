import 'package:flutter/material.dart';

class AdminCrowdAnalyticsScreen extends StatefulWidget {
  const AdminCrowdAnalyticsScreen({super.key});

  @override
  State<AdminCrowdAnalyticsScreen> createState() => _AdminCrowdAnalyticsScreenState();
}

class _AdminCrowdAnalyticsScreenState extends State<AdminCrowdAnalyticsScreen> {
  final String _selectedRoute = 'Galle-Hapugala';
  final String _selectedPeriod = 'Today';

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
          'Crowd Analytics',
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
              child: Icon(Icons.person, color: Color(0xFF136AEC)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route and Period Selection
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFE0E6F2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Route: $_selectedRoute',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          Icon(Icons.expand_more, color: Color(0xFF999CA6)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE0E6F2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF136AEC), size: 16),
                        SizedBox(width: 6),
                        Text(
                          _selectedPeriod,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D131B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Current Stop Status
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on, color: Colors.green),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galle Bus Stand',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Current crowding level',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF999CA6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LOW DENSITY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Passenger Volume Trends
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passenger Volume Trends',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE0E6F2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WEEKLY TOTAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF999CA6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '12,482',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D131B),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up, color: Colors.green, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    '+3%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        // Simple Chart Representation
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            'MON',
                            'TUE',
                            'WED',
                            'THU',
                            'FRI',
                            'SAT',
                            'SUN',
                          ].asMap().entries.map((entry) {
                            int index = entry.key;
                            String day = entry.value;
                            List<double> heights = [0.4, 0.65, 0.5, 0.7, 0.55, 0.8, 0.3];
                            return Column(
                              children: [
                                Container(
                                  width: 6,
                                  height: heights[index] * 80,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF136AEC),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF999CA6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Route Crowding Levels
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      Text(
                        'AVG %',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      Text(
                        'TRENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...[
                    {'name': 'Galle-Hapugala', 'percent': '88%', 'trend': 'up', 'color': Colors.red},
                    {'name': 'Galle-Matara', 'percent': '75%', 'trend': 'down', 'color': Colors.orange},
                    {'name': 'Karapitiya Circle', 'percent': '92%', 'trend': 'up', 'color': Colors.red},
                  ].map((route) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            route['name'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (route['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              route['percent'].toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: route['color'] as Color,
                              ),
                            ),
                          ),
                          Icon(
                            route['trend'] == 'up'
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: route['color'] as Color,
                            size: 16,
                          ),
                        ],
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
}
