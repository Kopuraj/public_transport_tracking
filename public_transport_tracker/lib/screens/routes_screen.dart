import 'package:flutter/material.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final List<Map<String, dynamic>> routes = [
    {
      'routeNumber': '502',
      'from': 'Galle',
      'to': 'Hapugala',
      'departureTime': '06:00 AM',
      'arrivalTime': '06:45 AM',
      'stops': 12,
      'distance': '28 km',
      'fare': 'Rs. 45',
      'frequency': 'Every 15 mins',
      'status': 'Many Seats',
      'statusColor': Colors.green,
    },
    {
      'routeNumber': '503',
      'from': 'Galle',
      'to': 'Matara',
      'departureTime': '07:00 AM',
      'arrivalTime': '08:30 AM',
      'stops': 18,
      'distance': '42 km',
      'fare': 'Rs. 65',
      'frequency': 'Every 20 mins',
      'status': 'Standing Room Only',
      'statusColor': Colors.red,
    },
    {
      'routeNumber': '504',
      'from': 'Galle',
      'to': 'Colombo',
      'departureTime': '08:00 AM',
      'arrivalTime': '11:00 AM',
      'stops': 25,
      'distance': '118 km',
      'fare': 'Rs. 150',
      'frequency': 'Every 30 mins',
      'status': 'Few Seats',
      'statusColor': Colors.orange,
    },
    {
      'routeNumber': '505',
      'from': 'Galle',
      'to': 'Unawatuna',
      'departureTime': '06:30 AM',
      'arrivalTime': '07:00 AM',
      'stops': 5,
      'distance': '6 km',
      'fare': 'Rs. 20',
      'frequency': 'Every 10 mins',
      'status': 'Many Seats',
      'statusColor': Colors.green,
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
          'Available Routes',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE0E6F2)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: Color(0xFF4C6B9A)),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search routes...',
                          hintStyle: TextStyle(color: Color(0xFF4C6B9A)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Routes List
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return GestureDetector(
                    onTap: () {
                      _showRouteDetails(route);
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE0E6F2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route Number and Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF136AEC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Route ${route['routeNumber']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: route['statusColor'].withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: route['statusColor']),
                                ),
                                child: Text(
                                  route['status'],
                                  style: TextStyle(
                                    color: route['statusColor'],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // From - To
                          Row(
                            children: [
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
                                    SizedBox(height: 4),
                                    Text(
                                      route['from'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D131B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.arrow_forward,
                                      color: Color(0xFF136AEC)),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'TO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF999CA6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      route['to'],
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

                          // Divider
                          Container(
                            height: 1,
                            color: Color(0xFFE0E6F2),
                          ),
                          SizedBox(height: 12),

                          // Details Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(
                                'Departure',
                                route['departureTime'],
                              ),
                              _buildDetailItem(
                                'Stops',
                                '${route['stops']}',
                              ),
                              _buildDetailItem(
                                'Fare',
                                route['fare'],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Frequency
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFF6F7F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule,
                                    color: Color(0xFF136AEC), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Frequency: ${route['frequency']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF555D6E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF999CA6),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D131B),
          ),
        ),
      ],
    );
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Route ${route['routeNumber']} Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildDetailRow('From', route['from']),
              _buildDetailRow('To', route['to']),
              _buildDetailRow('Departure', route['departureTime']),
              _buildDetailRow('Arrival', route['arrivalTime']),
              _buildDetailRow('Number of Stops', route['stops'].toString()),
              _buildDetailRow('Distance', route['distance']),
              _buildDetailRow('Fare', route['fare']),
              _buildDetailRow('Frequency', route['frequency']),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Route ${route['routeNumber']} added to favorites'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF136AEC),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Add to Favorites',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999CA6),
              fontWeight: FontWeight.w500,
            ),
          ),
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
    );
  }
}
