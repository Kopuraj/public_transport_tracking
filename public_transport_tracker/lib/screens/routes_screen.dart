import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRoutes = [];
  List<Map<String, dynamic>> _filteredRoutes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _apiService.getAllRoutes();
      if (result['success'] == true) {
        final routes = List<Map<String, dynamic>>.from(result['routes'] ?? []);
        setState(() {
          _allRoutes = routes;
          _filteredRoutes = routes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load routes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot connect to server. Make sure backend is running.';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRoutes = _allRoutes.where((r) {
        return (r['routeNumber']?.toString().toLowerCase().contains(query) ?? false) ||
               (r['from']?.toString().toLowerCase().contains(query) ?? false) ||
               (r['to']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Available Routes',
          style: TextStyle(
            color: Color(0xFF0D131B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF136AEC)),
            onPressed: _loadRoutes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E6F2)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, color: Color(0xFF4C6B9A)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by route number or city...',
                        hintStyle: TextStyle(color: Color(0xFF4C6B9A)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _filteredRoutes.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadRoutes,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _filteredRoutes.length,
                              itemBuilder: (context, index) {
                                return _buildRouteCard(_filteredRoutes[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRoutes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF136AEC),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No routes found', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final statusColor = route['active'] == true ? Colors.green : Colors.grey;
    final stops = route['stops'] as List? ?? [];

    return GestureDetector(
      onTap: () => _showRouteDetails(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E6F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Number and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF136AEC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Route ${route['routeNumber'] ?? ''}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    route['active'] == true ? 'Active' : 'Inactive',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // From → To
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FROM',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF999CA6),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(route['from'] ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Color(0xFF136AEC)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TO',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF999CA6),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(route['to'] ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D131B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFE0E6F2)),
            const SizedBox(height: 12),

            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem('Departure', route['departureTime'] ?? '-'),
                _buildDetailItem('Stops', '${stops.length}'),
                _buildDetailItem('Fare', route['fare'] ?? '-'),
              ],
            ),
            const SizedBox(height: 12),

            // Frequency
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFF136AEC), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Frequency: ${route['frequency'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555D6E),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF999CA6),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D131B))),
      ],
    );
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    final stops = (route['stops'] as List? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Route ${route['routeNumber']} — ${route['from']} to ${route['to']}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D131B)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Departure', route['departureTime'] ?? '-'),
              _buildDetailRow('Arrival', route['arrivalTime'] ?? '-'),
              _buildDetailRow('Distance', route['distance'] ?? '-'),
              _buildDetailRow('Fare', route['fare'] ?? '-'),
              _buildDetailRow('Frequency', route['frequency'] ?? '-'),
              const SizedBox(height: 16),
              const Text('Stops',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D131B))),
              const SizedBox(height: 8),
              ...stops.asMap().entries.map((entry) {
                final i = entry.key;
                final stop = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: i == 0 || i == stops.length - 1
                              ? const Color(0xFF136AEC)
                              : const Color(0xFFE0E6F2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: i == 0 || i == stops.length - 1
                                      ? Colors.white
                                      : const Color(0xFF555D6E),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(stop['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF0D131B))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/trip-tracking',
                        arguments: route);
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Track Live Buses on This Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF136AEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999CA6),
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D131B))),
        ],
      ),
    );
  }
}
