import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  int _selectedTab = 0; // 0: Active, 1: Past, 2: Cancelled

  final List<Map<String, dynamic>> activeTickets = [
    {
      'ticketId': 'TK-2026-001',
      'routeNumber': '502',
      'from': 'Galle',
      'to': 'Hapugala',
      'date': 'Jan 18, 2026',
      'time': '06:00 AM',
      'seatNumber': 'A12',
      'fare': 'Rs. 45',
      'status': 'Confirmed',
      'boardingTime': '05:45 AM',
    },
    {
      'ticketId': 'TK-2026-002',
      'routeNumber': '504',
      'from': 'Galle',
      'to': 'Colombo',
      'date': 'Jan 19, 2026',
      'time': '08:00 AM',
      'seatNumber': 'B05',
      'fare': 'Rs. 150',
      'status': 'Confirmed',
      'boardingTime': '07:45 AM',
    },
  ];

  final List<Map<String, dynamic>> pastTickets = [
    {
      'ticketId': 'TK-2026-003',
      'routeNumber': '502',
      'from': 'Galle',
      'to': 'Hapugala',
      'date': 'Jan 17, 2026',
      'time': '06:00 AM',
      'seatNumber': 'C08',
      'fare': 'Rs. 45',
      'status': 'Completed',
    },
    {
      'ticketId': 'TK-2026-004',
      'routeNumber': '503',
      'from': 'Galle',
      'to': 'Matara',
      'date': 'Jan 16, 2026',
      'time': '07:00 AM',
      'seatNumber': 'A15',
      'fare': 'Rs. 65',
      'status': 'Completed',
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
          'My Tickets',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab(0, 'Active'),
                _buildTab(1, 'Past'),
                _buildTab(2, 'Cancelled'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildActiveTickets()
                : _selectedTab == 1
                    ? _buildPastTickets()
                    : _buildCancelledTickets(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color(0xFF136AEC) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Color(0xFF136AEC) : Color(0xFF999CA6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTickets() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: activeTickets.map((ticket) {
          return _buildTicketCard(ticket, isActive: true);
        }).toList(),
      ),
    );
  }

  Widget _buildPastTickets() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: pastTickets.map((ticket) {
          return _buildTicketCard(ticket, isActive: false);
        }).toList(),
      ),
    );
  }

  Widget _buildCancelledTickets() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, size: 64, color: Color(0xFFE0E6F2)),
          SizedBox(height: 16),
          Text(
            'No cancelled tickets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999CA6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, {required bool isActive}) {
    return GestureDetector(
      onTap: () => _showTicketDetails(ticket),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E6F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Color(0xFFF0F5FF) : Color(0xFFF6F7F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route ${ticket['routeNumber']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D131B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        ticket['ticketId'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999CA6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket['status'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Middle Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                            ticket['from'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward, color: Color(0xFF136AEC)),
                      Column(
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
                            ticket['to'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Color(0xFFE0E6F2),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTicketDetail('Date', ticket['date']),
                      _buildTicketDetail('Seat', ticket['seatNumber']),
                      _buildTicketDetail('Fare', ticket['fare']),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom Section
            if (isActive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: Color(0xFFE0E6F2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Board at',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999CA6),
                          ),
                        ),
                        Text(
                          ticket['boardingTime'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF136AEC),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Showing QR code for ticket ${ticket['ticketId']}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF136AEC),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: Text(
                        'Show QR',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildTicketDetail(String label, String value) {
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

  void _showTicketDetails(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Ticket ID', ticket['ticketId']),
              _buildDetailRow('Route', 'Route ${ticket['routeNumber']}'),
              _buildDetailRow('From', ticket['from']),
              _buildDetailRow('To', ticket['to']),
              _buildDetailRow('Date', ticket['date']),
              _buildDetailRow('Time', ticket['time']),
              _buildDetailRow('Seat', ticket['seatNumber']),
              _buildDetailRow('Fare', ticket['fare']),
              _buildDetailRow('Status', ticket['status']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
