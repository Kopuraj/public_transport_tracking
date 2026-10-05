import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RouteScheduleScreen extends StatefulWidget {
  const RouteScheduleScreen({super.key});

  @override
  State<RouteScheduleScreen> createState() => _RouteScheduleScreenState();
}

class _RouteScheduleScreenState extends State<RouteScheduleScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.getAllRoutes();
      if (!mounted) return;
      setState(() {
        _routes = List<Map<String, dynamic>>.from(response['routes'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Cannot load schedules. Check that the backend is running.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Route Schedules'),
        actions: [
          IconButton(onPressed: _loadRoutes, icon: const Icon(Icons.refresh)),
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
                      onPressed: _loadRoutes,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _routes.isEmpty
          ? const Center(child: Text('No routes have been added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                final stops = route['stops'] as List? ?? const [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.directions_bus,
                      color: Color(0xFF136AEC),
                    ),
                    title: Text(
                      'Route ${route['routeNumber'] ?? route['id'] ?? '-'}',
                    ),
                    subtitle: Text(
                      '${route['from'] ?? 'Unknown'} → ${route['to'] ?? 'Unknown'}\nFrequency: ${route['frequency'] ?? 'Not provided'}',
                    ),
                    children: [
                      ...stops.asMap().entries.map((entry) {
                        final stop = Map<String, dynamic>.from(
                          entry.value as Map,
                        );
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 13,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          title: Text(
                            stop['name']?.toString() ?? 'Stop ${entry.key + 1}',
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/trip-tracking',
                              arguments: route,
                            ),
                            icon: const Icon(Icons.location_on),
                            label: const Text('View Active Vehicles'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
