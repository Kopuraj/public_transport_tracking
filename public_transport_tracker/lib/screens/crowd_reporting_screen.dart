import 'package:flutter/material.dart';

class CrowdReportingScreen extends StatefulWidget {
  const CrowdReportingScreen({super.key});

  @override
  State<CrowdReportingScreen> createState() => _CrowdReportingScreenState();
}

class _CrowdReportingScreenState extends State<CrowdReportingScreen> {
  int _selectedCrowding = 1; // 0: Many Seats, 1: Few Seats, 2: Very Crowded
  bool _acWorking = true;
  bool _wheelchairAccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Bus #502 HAPUGALA',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Question Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How crowded is this bus?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bus #502 TO HAPUGALA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999CA6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Crowding Options
                  _buildCrowdingOption(0, 'Many Seats', '🟢', Colors.green),
                  SizedBox(height: 12),
                  _buildCrowdingOption(1, 'Few Seats', '🟡', Colors.orange),
                  SizedBox(height: 12),
                  _buildCrowdingOption(2, 'Very Crowded', '🔴', Colors.red),
                ],
              ),
            ),

            // Features Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 16),

                  // AC Working Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.ac_unit, color: Color(0xFF136AEC), size: 20),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AC Working?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Air conditioning functional',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF999CA6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _acWorking,
                        onChanged: (value) => setState(() => _acWorking = value),
                        activeThumbColor: Color(0xFF136AEC),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Wheelchair Accessibility Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wheelchair_pickup, color: Color(0xFF136AEC), size: 20),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wheelchair Range?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Wheelchair accessibility available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF999CA6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _wheelchairAccess,
                        onChanged: (value) => setState(() => _wheelchairAccess = value),
                        activeThumbColor: Color(0xFF136AEC),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Submit Button
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String crowdingLevel = ['Many Seats', 'Few Seats', 'Very Crowded']
                        [_selectedCrowding];
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Report Submitted'),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Your bus crowding report has been submitted!',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F5FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Report Details:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Crowding: $crowdingLevel'),
                                  Text('AC: ${_acWorking ? 'Working' : 'Not Working'}'),
                                  Text(
                                      'Wheelchair: ${_wheelchairAccess ? 'Available' : 'Not Available'}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF136AEC),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Submit Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrowdingOption(int index, String label, String emoji, Color color) {
    bool isSelected = _selectedCrowding == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCrowding = index),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Color(0xFFE0E6F2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    index == 0
                        ? 'Lots of empty seats'
                        : index == 1
                            ? 'Limited seating available'
                            : 'Standing room only',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999CA6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
