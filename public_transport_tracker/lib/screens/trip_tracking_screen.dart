import 'package:flutter/material.dart';

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  int _selectedLoad = 2; // 0: Light, 1: Medium, 2: Heavy

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Galle - Hapugala',
              style: TextStyle(
                color: Color(0xFF0D131B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'To Ruhuna Engineering',
              style: TextStyle(
                color: Color(0xFF999CA6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'VALIDATED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            Container(
              height: 250,
              color: Colors.white,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E6F2)),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/-74.0,40.7,12,0,0/400x300@2x?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycW1vNHprM3JzbDgifQ.rJcFIG214AriISLbB6B5aw',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFF136AEC),
                      size: 40,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
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
                      child: Icon(
                        Icons.my_location,
                        color: Color(0xFF136AEC),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Next Stop Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E6F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NEXT STOP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF136AEC),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF136AEC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '3 min',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Karapitiya Junction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Arriving at 8:45 AM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '• On Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Journey Progress Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E6F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_bus, color: Color(0xFF136AEC)),
                          SizedBox(width: 8),
                          Text(
                            'Heading to Hapugala',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '60%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF136AEC),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE0E6F2),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF136AEC)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Started: 8:25 AM',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999CA6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '4 stops remaining',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999CA6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bus Load Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E6F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Color(0xFF136AEC), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Current bus load',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLoadOption(0, 'LIGHT'),
                      _buildLoadOption(1, 'MEDIUM'),
                      _buildLoadOption(2, 'HEAVY'),
                    ],
                  ),
                ],
              ),
            ),

            // Timeline Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E6F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Timeline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTimelineItem('Started', '8:25 AM', 'Galle Fort', true),
                  _buildTimelineItem('Next', '8:45 AM', 'Karapitiya Junction', false),
                  _buildTimelineItem('Stop', '9:00 AM', 'Wakwella Road', false),
                  _buildTimelineItem('Stop', '9:15 AM', 'Matara City', false),
                  _buildTimelineItem('Final', '9:30 AM', 'Faculty of Engineering', false),
                ],
              ),
            ),

            // Action Buttons
            Container(
              margin: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Issue reported')),
                        );
                      },
                      icon: Icon(Icons.report_problem),
                      label: Text('Report Issue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('End Trip?'),
                            content: Text('Are you sure you want to end this trip?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Trip ended'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: Text('End Trip', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'End Current Trip',
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
      ),
    );
  }

  Widget _buildLoadOption(int index, String label) {
    bool isSelected = _selectedLoad == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedLoad = index),
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF0F5FF) : Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF136AEC) : Color(0xFFE0E6F2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.group,
              color: isSelected ? Color(0xFF136AEC) : Color(0xFF999CA6),
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF136AEC) : Color(0xFF999CA6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String type, String time, String location, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Timeline Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Color(0xFF136AEC) : Color(0xFFE0E6F2),
            ),
          ),
          SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D131B),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999CA6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999CA6),
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
