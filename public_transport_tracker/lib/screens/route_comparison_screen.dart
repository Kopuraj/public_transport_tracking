import 'package:flutter/material.dart';

class RouteComparisonScreen extends StatefulWidget {
  const RouteComparisonScreen({super.key});

  @override
  State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
  int _selectedFilter = 0; // 0: All, 1: Fastest, 2: Frequent, 3: Cheapest

  final List<Map<String, dynamic>> routes = [
    {
      'duration': '25 min',
      'via': 'via Karapitiya Junction',
      'routeNumber': '502',
      'routeName': 'GALLE - HAPUGALA',
      'badge': 'BEST CHOICE',
      'availability': 'SEATS AVAILABLE',
      'availabilityColor': Colors.green,
      'icon': Icons.accessibility,
      'stops': 4,
      'frequency': 'Departs every 15 mins. Usually high seat availability.',
      'price': 'Rs. 45',
      'isBestChoice': true,
    },
    {
      'duration': '22 min',
      'via': 'via Wakwella Road',
      'routeNumber': '384',
      'routeName': 'WAKWELLA',
      'badge': 'CROWDED',
      'availability': 'CROWDED',
      'availabilityColor': Colors.red,
      'icon': Icons.group,
      'stops': 3,
      'frequency': 'Higher traffic expected near the Wakwella bridge.',
      'price': 'Rs. 50',
      'warning': true,
      'isBestChoice': false,
    },
    {
      'duration': '20 min',
      'via': 'Direct Hire',
      'routeNumber': 'THREE-WHEELER',
      'routeName': 'THREE-WHEELER',
      'badge': 'PREMIUM',
      'availability': 'DIRECT',
      'availabilityColor': Colors.orange,
      'icon': Icons.local_taxi,
      'stops': 0,
      'frequency': 'Direct hire service with no stops.',
      'price': 'LKR 600+',
      'isBestChoice': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Galle Route Comparison',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // From/To Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF136AEC), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FROM',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF999CA6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Galle Town Bus Stand',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D131B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(height: 1, color: Color(0xFFE0E6F2)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF999CA6), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TO',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF999CA6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Faculty of Engineering, Hapugala',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D131B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Locations swapped')),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF6F7F8),
                            border: Border.all(color: Color(0xFFE0E6F2)),
                          ),
                          child: Icon(Icons.swap_vert, color: Color(0xFF999CA6), size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'All Routes'),
                    SizedBox(width: 8),
                    _buildFilterChip(1, 'Fastest'),
                    SizedBox(width: 8),
                    _buildFilterChip(2, 'Frequent'),
                    SizedBox(width: 8),
                    _buildFilterChip(3, 'Cheapest'),
                  ],
                ),
              ),
            ),

            // Routes List
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: routes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> route = entry.value;
                  return _buildRouteCard(route, index == 0);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF136AEC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF136AEC) : Color(0xFFE0E6F2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Color(0xFF555D6E),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, bool isBest) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBest ? Color(0xFF136AEC) : Color(0xFFE0E6F2),
          width: isBest ? 2 : 1,
        ),
        boxShadow: isBest
            ? [
                BoxShadow(
                  color: Color(0xFF136AEC).withValues(alpha: 0.1),
                  blurRadius: 12,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header with Badge
          if (isBest || route['warning'] != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isBest ? Color(0xFFF0F5FF) : Color(0xFFFFE8E8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isBest ? Color(0xFF136AEC) : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      route['badge'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (route['availabilityColor'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: route['availabilityColor'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        route['availability'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: route['availabilityColor'],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Main Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      route['duration'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D131B),
                      ),
                    ),
                    Text(
                      route['via'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999CA6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Route Info
                if (route['routeNumber'] != 'THREE-WHEELER')
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.accessibility, color: Color(0xFF136AEC), size: 20),
                            SizedBox(width: 12),
                            Text(
                              route['routeNumber'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF136AEC),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          route['routeName'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF136AEC),
                          ),
                        ),
                        Icon(Icons.school, color: Color(0xFF136AEC), size: 20),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_taxi, color: Color(0xFF136AEC), size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Three-Wheeler (Direct Hire)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF136AEC),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Info Text
                if (route['warning'] != null)
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          route['frequency'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    route['frequency'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF555D6E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected Route ${route['routeNumber']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBest ? Color(0xFF136AEC) : Colors.grey[400],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Select Route',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
