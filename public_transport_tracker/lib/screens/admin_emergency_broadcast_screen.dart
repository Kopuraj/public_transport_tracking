import 'package:flutter/material.dart';

class AdminEmergencyBroadcastScreen extends StatefulWidget {
  const AdminEmergencyBroadcastScreen({super.key});

  @override
  State<AdminEmergencyBroadcastScreen> createState() => _AdminEmergencyBroadcastScreenState();
}

class _AdminEmergencyBroadcastScreenState extends State<AdminEmergencyBroadcastScreen> {
  String? _selectedRoute;
  String? _selectedAlertType;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D131B),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1F3A),
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Broadcast Control',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Icon(Icons.settings, color: Color(0xFF136AEC)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Alert Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Alert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Draft saved 2m ago',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999CA6),
                    ),
                  ),
                ],
              ),
            ),

            // Route Selection
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Selection',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF2A2F4A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedRoute ?? 'Route 502 (Galle-Matara)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.expand_more, color: Color(0xFF999CA6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Alert Type Selection
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF2A2F4A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.warning_amber,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _selectedAlertType ?? 'Severe Weather Condition',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.expand_more, color: Color(0xFF999CA6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Custom Message
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Message',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF2A2F4A)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            'Route 502 delayed due to road work at Hapugala. Expect 20 min delays.',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999CA6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Broadcast Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alert broadcasted successfully!'),
                        backgroundColor: Color(0xFF136AEC),
                      ),
                    );
                  },
                  icon: Icon(Icons.broadcast_on_home),
                  label: Text('Broadcast Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF136AEC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Live Feed Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Feed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF136AEC),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Alert 1
                  _buildLiveAlertCard(
                    title: 'Route 502: Hapugala Block',
                    timestamp: '20 mins ago',
                    message: 'Heavy machinery blocking main lane near Hapugala Junction. Emergency services on site.',
                    color: Colors.red,
                  ),
                  SizedBox(height: 10),
                  // Alert 2
                  _buildLiveAlertCard(
                    title: 'WEATHER',
                    timestamp: '35 mins ago',
                    message: 'Regional Heavy Rain: Slow moving traffic across all Southern coastal routes due to visibility issues.',
                    color: Colors.blue,
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

  Widget _buildLiveAlertCard({
    required String title,
    required String timestamp,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF999CA6),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFB0B5C0),
            ),
          ),
        ],
      ),
    );
  }
}
