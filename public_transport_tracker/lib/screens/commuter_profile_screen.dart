import 'package:flutter/material.dart';

class CommuterProfileScreen extends StatefulWidget {
  const CommuterProfileScreen({super.key});

  @override
  State<CommuterProfileScreen> createState() => _CommuterProfileScreenState();
}

class _CommuterProfileScreenState extends State<CommuterProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Commuter Profile',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Color(0xFF136AEC)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share profile')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF136AEC),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF136AEC).withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Kasun Perera',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Senior Commuter • Sri Lanka',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999CA6),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✨ Trusted Member',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '⭐ 450 Points',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Earned Badges Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Earned Badges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF136AEC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBadge('Early Bird', '🌅', 'Catch early morning buses'),
                      _buildBadge('Trip Companion', '🤝', 'Top commuter this week'),
                      _buildBadge('Daily Rider', '📅', '30+ trips completed'),
                      _buildBadge('Helper', '🆘', 'Helped 5+ passengers'),
                    ],
                  ),
                ],
              ),
            ),

            // Commute Patterns
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commute Patterns',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildPatternRow('Most Used Route', 'Route #502 - Galle → Hapugala', '45 trips'),
                  SizedBox(height: 12),
                  _buildPatternRow('Peak Travel Time', '7:30 AM - 9:00 AM', '28 trips'),
                  SizedBox(height: 12),
                  _buildPatternRow('Favorite Stop', 'Karapitiya Junction', '15 times'),
                ],
              ),
            ),

            // Activity Stats
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Total Trips', '156', Color(0xFF136AEC)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Avg. Rating', '4.8/5', Colors.orange),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Reports Made', '34', Colors.green),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildStatCard('Money Saved', 'Rs. 4,250', Colors.purple),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('CO₂ Saved', '124 kg', Colors.teal),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Days Active', '67', Colors.pink),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Recent Activity
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildActivityItem('Reported crowding on Route #502', '2 hours ago', Colors.blue),
                  SizedBox(height: 12),
                  _buildActivityItem('Completed 10th trip this month', 'Yesterday', Colors.green),
                  SizedBox(height: 12),
                  _buildActivityItem('Earned "Trip Companion" badge', '3 days ago', Colors.purple),
                  SizedBox(height: 12),
                  _buildActivityItem('Reached 450 commuter points', '1 week ago', Colors.orange),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, String emoji, String description) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title - $description')),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F5FF),
              border: Border.all(color: Color(0xFFE0E6F2)),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 28)),
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRow(String label, String value, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999CA6),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D131B),
              ),
            ),
          ],
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF136AEC),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D131B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999CA6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
