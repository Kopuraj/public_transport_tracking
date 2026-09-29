import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';

class FindBusScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onBusSelected;

  const FindBusScreen({
    super.key,
    required this.onBusSelected,
  });

  @override
  State<FindBusScreen> createState() => _FindBusScreenState();
}

class _FindBusScreenState extends State<FindBusScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(6.0329, 80.2168);
  LatLng? _pickup;
  LatLng? _destination;
  bool _selectingPickup = true;
  bool _searching = false;
  String? _error;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final current = await MapService().getCurrentLocation();
    if (!mounted || current == null) return;

    setState(() {
      _center = current;
    });
    _mapController.move(current, 13);
  }

  void _onMapTap(LatLng point) {
    setState(() {
      if (_selectingPickup) {
        _pickup = point;
      } else {
        _destination = point;
      }
      _error = null;
    });
  }

  Future<void> _searchBuses() async {
    if (_pickup == null || _destination == null) {
      setState(() {
        _error = 'Set both pickup and destination points on the map.';
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _matches = [];
    });

    try {
      final result = await _apiService.findBuses(
        passengerLat: _pickup!.latitude,
        passengerLng: _pickup!.longitude,
        destinationLat: _destination!.latitude,
        destinationLng: _destination!.longitude,
      );

      if (!mounted) return;

      setState(() {
        _matches = List<Map<String, dynamic>>.from(result['matches'] ?? []);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    if (_pickup != null) {
      markers.add(MapService().createUserMarker(_pickup!));
    }
    if (_destination != null) {
      markers.add(
        Marker(
          point: _destination!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E6F2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Set Pickup'),
                      selected: _selectingPickup,
                      onSelected: (_) => setState(() => _selectingPickup = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Set Destination'),
                      selected: !_selectingPickup,
                      onSelected: (_) => setState(() => _selectingPickup = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _pickup == null
                          ? 'Pickup: Not set'
                          : 'Pickup: ${_pickup!.latitude.toStringAsFixed(5)}, ${_pickup!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _destination == null
                          ? 'Destination: Not set'
                          : 'Destination: ${_destination!.latitude.toStringAsFixed(5)}, ${_destination!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _searching ? null : _searchBuses,
                      icon: const Icon(Icons.search),
                      label: Text(_searching ? 'Searching...' : 'Search Available Buses'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136AEC),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _pickup = null;
                        _destination = null;
                        _matches = [];
                        _error = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        Container(
          height: 240,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E6F2)),
          ),
          child: MapService().createMap(
            center: _center,
            mapController: _mapController,
            zoom: 13,
            markers: markers,
            onTap: _onMapTap,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _matches.isEmpty
              ? Center(
                  child: Text(
                    _searching
                        ? 'Searching for matching buses...'
                        : 'Select pickup and destination, then search.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    final route = Map<String, dynamic>.from(match['route'] ?? {});
                    final pickupStop = Map<String, dynamic>.from(match['pickupStop'] ?? {});
                    final dropoffStop = Map<String, dynamic>.from(match['dropoffStop'] ?? {});

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route ${route['routeNumber'] ?? match['routeId'] ?? '-'}: ${route['from'] ?? '-'} to ${route['to'] ?? '-'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text('Bus: ${match['vehicleId'] ?? 'Unknown'}'),
                            Text('Crowd: ${match['crowdLevel'] ?? 'unknown'} (${match['occupancy'] ?? 0})'),
                            Text('Pickup stop: ${pickupStop['name'] ?? '-'}'),
                            Text('Dropoff stop: ${dropoffStop['name'] ?? '-'}'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => widget.onBusSelected(match),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF136AEC),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Track This Bus'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
