import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PassengerTicketScreen extends StatefulWidget {
  const PassengerTicketScreen({super.key});

  @override
  State<PassengerTicketScreen> createState() => _PassengerTicketScreenState();
}

class _PassengerTicketScreenState extends State<PassengerTicketScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getActiveTrips(),
        _api.getMyTickets(),
      ]);
      if (!mounted) return;
      setState(() {
        _trips = List<Map<String, dynamic>>.from(results[0]['trips'] ?? []);
        _tickets = List<Map<String, dynamic>>.from(results[1]['tickets'] ?? []);
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  Future<void> _chooseJourney(Map<String, dynamic> trip) async {
    final route = Map<String, dynamic>.from(trip['route'] ?? {});
    final stops = (route['stops'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    if (stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This route does not have enough configured stops.'),
        ),
      );
      return;
    }
    int pickup = 0;
    int dropoff = stops.length - 1;
    int passengers = 1;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route ${route['routeNumber'] ?? trip['routeId']} · ${trip['vehicleId']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: pickup,
                decoration: const InputDecoration(
                  labelText: 'Pickup stop',
                  border: OutlineInputBorder(),
                ),
                items: stops
                    .asMap()
                    .entries
                    .take(stops.length - 1)
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value['name']?.toString() ??
                              'Stop ${entry.key + 1}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setSheetState(() {
                  pickup = value ?? 0;
                  if (dropoff <= pickup) dropoff = pickup + 1;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('$pickup-$dropoff'),
                initialValue: dropoff,
                decoration: const InputDecoration(
                  labelText: 'Drop-off stop',
                  border: OutlineInputBorder(),
                ),
                items: stops
                    .asMap()
                    .entries
                    .where((entry) => entry.key > pickup)
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value['name']?.toString() ??
                              'Stop ${entry.key + 1}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => dropoff = value ?? pickup + 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Passengers',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: passengers > 1
                        ? () => setSheetState(() => passengers--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$passengers',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: passengers < 4
                        ? () => setSheetState(() => passengers++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Text(
                'Fare: ${route['fare'] ?? 'Pay on bus'}',
                style: const TextStyle(color: Color(0xFF555D6E)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _api.createTicket(
                        tripId: trip['id'].toString(),
                        pickupStopIndex: pickup,
                        dropoffStopIndex: dropoff,
                        passengerCount: passengers,
                      );
                      if (sheetContext.mounted)
                        Navigator.pop(sheetContext, true);
                    } catch (error) {
                      if (sheetContext.mounted)
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  },
                  child: const Text('Confirm Free Digital Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (created == true) {
      await _refresh();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Get a ticket',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose a vehicle that is currently operated by a driver.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (_trips.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No live vehicles are available. A driver must start a trip first.',
                        ),
                      ),
                    )
                  else
                    ..._trips.map((trip) {
                      final route = Map<String, dynamic>.from(
                        trip['route'] ?? {},
                      );
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.directions_bus,
                            color: Color(0xFF136AEC),
                          ),
                          title: Text(
                            'Route ${route['routeNumber'] ?? trip['routeId']} · ${trip['vehicleId']}',
                          ),
                          subtitle: Text(
                            '${route['from'] ?? 'Unknown'} → ${route['to'] ?? 'Unknown'}\n${trip['occupancy'] ?? 0}/${trip['capacity'] ?? 55} passengers',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _chooseJourney(trip),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  const Text(
                    'My tickets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_tickets.isEmpty)
                    const Text(
                      'You have no tickets yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._tickets.map(
                      (ticket) => Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Route ${ticket['routeNumber']}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ticket['status']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'CONFIRMED',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text('Vehicle ${ticket['vehicleId']}'),
                              const Divider(),
                              Text(
                                '${ticket['pickupStop']} → ${ticket['dropoffStop']}',
                              ),
                              Text(
                                'Passengers: ${ticket['passengerCount']} · ${ticket['fare']}',
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                ticket['ticketCode']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
