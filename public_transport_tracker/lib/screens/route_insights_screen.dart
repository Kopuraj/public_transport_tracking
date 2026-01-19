import 'package:flutter/material.dart';

class RouteInsightsScreen extends StatefulWidget {
  const RouteInsightsScreen({super.key});

  @override
  State<RouteInsightsScreen> createState() => _RouteInsightsScreenState();
}

class _RouteInsightsScreenState extends State<RouteInsightsScreen> {
  int _selectedRoute = 0; // 0: Route 502, 1: Route 503, etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Route Insights',
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
            // Route Selection
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRouteTab(0, 'Route 502'),
                    SizedBox(width: 8),
                    _buildRouteTab(1, 'Route 503'),
                    SizedBox(width: 8),
                    _buildRouteTab(2, 'Route 504'),
                  ],
                ),
              ),
            ),

            // Crowding Analytics
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crowding Analytics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Date - Hourly Route Data (502)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999CA6),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Chart
                  Container(
                    height: 180,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: _buildCrowdingChart(),
                  ),

                  SizedBox(height: 16),

                  // Peak Hour Info
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
                          'Peak Hours Analysis',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF136AEC),
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildPeakHourItem('High at 8:00 AM', '+29%', Colors.red),
                        SizedBox(height: 8),
                        _buildPeakHourItem('Medium at 5:00 PM', '+15%', Colors.orange),
                        SizedBox(height: 8),
                        _buildPeakHourItem('Low at 10:00 AM', '-40%', Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Community Feed
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Community Feed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Refreshing feed')),
                          );
                        },
                        child: Text(
                          'Refresh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF136AEC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Feed Item 1 - Alert
                  _buildFeedItem(
                    title: 'Bus #502 Delayed',
                    description: 'Current delay: 15 minutes on Marine Drive. Traffic congestion reported.',
                    icon: Icons.warning,
                    iconColor: Colors.red,
                    time: '5 min ago',
                    author: 'Kasun Perera',
                  ),
                  SizedBox(height: 12),

                  // Feed Item 2 - Report
                  _buildFeedItem(
                    title: 'Currently Very Crowded',
                    description: 'Bus #502 is standing room only. Suggest taking the next bus.',
                    icon: Icons.info,
                    iconColor: Colors.blue,
                    time: '12 min ago',
                    author: 'Sarah Wilson',
                  ),
                  SizedBox(height: 12),

                  // Feed Item 3 - Traffic Alert
                  _buildFeedItem(
                    title: 'Traffic Alert',
                    description: 'Clear traffic on Galle Road. Expect on-time arrivals for Route #502.',
                    icon: Icons.directions_car,
                    iconColor: Colors.green,
                    time: '28 min ago',
                    author: 'System Alert',
                  ),
                  SizedBox(height: 12),

                  // Feed Item 4 - Positive Report
                  _buildFeedItem(
                    title: 'Excellent Service',
                    description:
                        'Driver was very helpful and AC working perfectly. Great commute experience!',
                    icon: Icons.thumb_up,
                    iconColor: Colors.green,
                    time: '1 hour ago',
                    author: 'Dilshan Kumar',
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening report form')),
                        );
                      },
                      icon: Icon(Icons.add_comment),
                      label: Text('Submit Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF136AEC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Showing route details')),
                        );
                      },
                      icon: Icon(Icons.info_outline),
                      label: Text('View Route Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF136AEC),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTab(int index, String label) {
    bool isSelected = _selectedRoute == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoute = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF136AEC) : Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF136AEC) : Color(0xFFE0E6F2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Color(0xFF555D6E),
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdingChart() {
    List<double> data = [0.3, 0.5, 0.7, 0.9, 0.75, 0.6, 0.4, 0.5, 0.8, 0.95, 0.85, 0.6];
    double maxHeight = 140;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (index) {
        double height = data[index] * maxHeight;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: height,
              decoration: BoxDecoration(
                color: data[index] > 0.7 ? Colors.red : data[index] > 0.4 ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${index + 8}h',
              style: TextStyle(fontSize: 8, color: Color(0xFF999CA6)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPeakHourItem(String label, String change, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555D6E),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            change,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedItem({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String time,
    required String author,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D131B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF999CA6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF999CA6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555D6E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
