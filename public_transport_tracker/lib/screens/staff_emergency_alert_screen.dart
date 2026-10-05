import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffEmergencyAlertScreen extends StatefulWidget {
  final String? tripId;
  final String? routeLabel;
  final int passengerCount;

  const StaffEmergencyAlertScreen({
    super.key,
    this.tripId,
    this.routeLabel,
    this.passengerCount = 0,
  });

  @override
  State<StaffEmergencyAlertScreen> createState() =>
      _StaffEmergencyAlertScreenState();
}

class _StaffEmergencyAlertScreenState extends State<StaffEmergencyAlertScreen> {
  String? _selectedEmergency;
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _broadcast() async {
    if (widget.tripId == null || _selectedEmergency == null) return;
    setState(() => _sending = true);
    try {
      final selected = _emergencyTypes.firstWhere(
        (item) => item['id'] == _selectedEmergency,
      );
      final custom = _messageController.text.trim();
      await ApiService().sendEmergencyAlert(
        tripId: widget.tripId!,
        alertType: _selectedEmergency!,
        message: custom.isEmpty ? selected['description'].toString() : custom,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert broadcast to passengers'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'id': 'breakdown',
      'icon': Icons.warning_amber,
      'title': 'Vehicle Breakdown',
      'description': 'Report mechanical or technical failure',
      'color': Colors.orange,
    },
    {
      'id': 'traffic',
      'icon': Icons.traffic,
      'title': 'Heavy Traffic',
      'description': 'Significant delay on current route',
      'color': Colors.red,
    },
    {
      'id': 'medical',
      'icon': Icons.local_hospital,
      'title': 'Medical Emergency',
      'description': 'Passenger or staff medical issue',
      'color': Colors.deepPurple,
    },
    {
      'id': 'closure',
      'icon': Icons.block,
      'title': 'Road Closure',
      'description': 'Route is blocked or inaccessible',
      'color': Colors.red,
    },
  ];

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
          'Emergency Alert',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Alert Header
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.red.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.red, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert All Passengers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select emergency type to broadcast',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999CA6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Emergency Type Selection
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Emergency Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B),
                    ),
                  ),
                  SizedBox(height: 14),
                  ..._emergencyTypes.map((emergency) {
                    bool isSelected = _selectedEmergency == emergency['id'];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmergency = emergency['id'];
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? emergency['color'].withValues(alpha: 0.1)
                                : Color(0xFFF6F7F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? emergency['color']
                                  : Color(0xFFE0E6F2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: emergency['color'].withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  emergency['icon'],
                                  color: emergency['color'],
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emergency['title'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: emergency['color'],
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      emergency['description'],
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
                                  color: emergency['color'],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Alert Message Section
            if (_selectedEmergency != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message to Passengers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D131B),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFE0E6F2)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Type additional message for passengers (optional)...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999CA6),
                          ),
                        ),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tip: Keep messages clear and concise for quick understanding',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF999CA6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Distribution Preview Section
            if (_selectedEmergency != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribution Info',
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
                        color: Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFE0E6F2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recipients:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              Text(
                                widget.routeLabel ?? 'Current active trip',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF136AEC),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Passenger Count:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              Text(
                                '${widget.passengerCount} passengers',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF999CA6),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dispatch HQ:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D131B),
                                ),
                              ),
                              Text(
                                'Connected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Broadcast Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _selectedEmergency == null ||
                          widget.tripId == null ||
                          _sending
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text('Broadcast Emergency Alert?'),
                              content: Text(
                                'This alert will be sent to all passengers on this route immediately.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text(
                                    'Broadcast',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) await _broadcast();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_sending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(Icons.broadcast_on_home, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        _sending ? 'SENDING...' : 'BROADCAST ALERT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Cancel Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel'),
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
