import 'package:flutter/material.dart';

class ScheduleFeedbackScreen extends StatefulWidget {
  const ScheduleFeedbackScreen({super.key});

  @override
  State<ScheduleFeedbackScreen> createState() => _ScheduleFeedbackScreenState();
}

class _ScheduleFeedbackScreenState extends State<ScheduleFeedbackScreen> {
  String _selectedTab = 'OVERVIEW';

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
          'Schedule & Feedback',
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
              child: Icon(Icons.refresh, color: Color(0xFF136AEC)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Navigation
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  'OVERVIEW',
                  'ANALYSIS',
                  'ROUTES',
                ].map((tab) {
                  bool isSelected = _selectedTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: Column(
                        children: [
                          Text(
                            tab,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Color(0xFF136AEC)
                                  : Color(0xFF999CA6),
                            ),
                          ),
                          SizedBox(height: 8),
                          if (isSelected)
                            Container(
                              height: 3,
                              color: Color(0xFF136AEC),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Divider(height: 1, color: Color(0xFFE0E6F2)),

            SizedBox(height: 20),

            // Dispatch Timeline Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dispatch Timeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Live Updates',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  // Timeline Items
                  ...[
                    {'time': '06 MAT', 'status': 'SCHEDULED', 'color': Colors.blue},
                    {'time': '06 MAT', 'status': 'SCHEDULED', 'color': Colors.blue},
                    {'time': '06 MAT', 'status': 'IN PROGRESS', 'color': Colors.green},
                    {'time': '06 INK', 'status': 'SCHEDULED', 'color': Colors.blue},
                    {'time': '06 INK', 'status': 'SCHEDULED', 'color': Colors.blue},
                    {'time': '06 INK', 'status': 'DELAYED', 'color': Colors.orange},
                  ].map((item) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item['color'] as Color,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                item['time'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['status'].toString(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: item['color'] as Color,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.more_vert,
                            color: Color(0xFF999CA6),
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Commuter Feedback Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commuter Feedback',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          '+ 25% POSITIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  // Feedback 1 - Positive
                  _buildFeedbackCard(
                    name: 'Sarah Mitchell',
                    username: 'sarah_m • 08:23 AM',
                    feedback:
                        'The new app is exceptionally clean and easy to use. AC was well functioning. Very happy with the hygiene standards.',
                    sentiment: 'POSITIVE',
                    sentimentColor: Colors.green,
                    avatar: 'SM',
                  ),
                  SizedBox(height: 12),
                  // Feedback 2 - Negative
                  _buildFeedbackCard(
                    name: 'Anonymous',
                    username: 'Anonymous • 08:00 AM',
                    feedback:
                        'The GPS bus tracking is definitely excellent. However, why did this driver speed so much and drive around curves too fast. Please check the GPS records for your safety.',
                    sentiment: 'NEGATIVE',
                    sentimentColor: Colors.red,
                    avatar: 'AN',
                  ),
                  SizedBox(height: 12),
                  // Feedback 3 - Positive
                  _buildFeedbackCard(
                    name: 'Albert S.',
                    username: 'albert_s • 07:45 AM',
                    feedback:
                        'Great service and excellent driver. Very professional handling of the vehicle and smooth journey throughout.',
                    sentiment: 'POSITIVE',
                    sentimentColor: Colors.green,
                    avatar: 'AS',
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard({
    required String name,
    required String username,
    required String feedback,
    required String sentiment,
    required Color sentimentColor,
    required String avatar,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(10),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF136AEC),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999CA6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sentiment,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: sentimentColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 14, color: Color(0xFF999CA6)),
                  SizedBox(width: 12),
                  Icon(Icons.share, size: 14, color: Color(0xFF999CA6)),
                ],
              ),
              Icon(Icons.more_vert, size: 14, color: Color(0xFF999CA6)),
            ],
          ),
        ],
      ),
    );
  }
}
