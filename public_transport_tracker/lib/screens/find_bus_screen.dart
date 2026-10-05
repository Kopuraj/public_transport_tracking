import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';

class FindBusScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onBusSelected;

  const FindBusScreen({super.key, required this.onBusSelected});

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
  List<Map<String, dynamic>> _stops = [];
  List<Polyline> _routeLines = [];
  String? _pickupName;
  String? _destinationName;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _loadStops();
  }

  Future<void> _loadStops() async {
    try {
      final result = await _apiService.getAllRoutes();
      final routes = List<Map<String, dynamic>>.from(result['routes'] ?? []);
      final unique = <String, Map<String, dynamic>>{};
      final lines = <Polyline>[];
      for (final route in routes) {
        final points = <LatLng>[];
        for (final raw in (route['stops'] as List? ?? const [])) {
          final stop = Map<String, dynamic>.from(raw as Map);
          final lat = (stop['lat'] ?? stop['latitude']) as num?;
          final lng = (stop['lng'] ?? stop['longitude']) as num?;
          if (lat == null || lng == null) continue;
          final location = LatLng(lat.toDouble(), lng.toDouble());
          points.add(location);
          final name = stop['name']?.toString() ?? 'Bus stop';
          unique['$name:${location.latitude}:${location.longitude}'] = {
            'name': name,
            'location': location,
          };
        }
        if (points.length > 1) {
          lines.add(MapService().createRoutePolyline(points));
        }
      }
      if (mounted) {
        setState(() {
          _stops = unique.values.toList();
          _routeLines = lines;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not load route stops: $error');
      }
    }
  }

  void _chooseStop(String? key, bool pickup) {
    if (key == null) return;
    final stop = _stops.firstWhere(
      (item) =>
          '${item['name']}:${(item['location'] as LatLng).latitude}:${(item['location'] as LatLng).longitude}' ==
          key,
    );
    final location = stop['location'] as LatLng;
    setState(() {
      if (pickup) {
        _pickup = location;
        _pickupName = stop['name'].toString();
      } else {
        _destination = location;
        _destinationName = stop['name'].toString();
      }
      _error = null;
    });
    _mapController.move(location, 14);
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
        _pickupName = 'Selected map location';
      } else {
        _destination = point;
        _destinationName = 'Selected map location';
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
      _hasSearched = true;
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Pickup stop',
                  prefixIcon: Icon(Icons.my_location),
                ),
                isExpanded: true,
                value: _pickupName == null
                    ? null
                    : _stops
                          .where((s) => s['name'] == _pickupName)
                          .map(
                            (s) =>
                                '${s['name']}:${(s['location'] as LatLng).latitude}:${(s['location'] as LatLng).longitude}',
                          )
                          .firstOrNull,
                items: _stops.map((stop) {
                  final p = stop['location'] as LatLng;
                  return DropdownMenuItem(
                    value: '${stop['name']}:${p.latitude}:${p.longitude}',
                    child: Text(stop['name'].toString()),
                  );
                }).toList(),
                onChanged: (value) => _chooseStop(value, true),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Destination stop',
                  prefixIcon: Icon(Icons.flag),
                ),
                isExpanded: true,
                value: _destinationName == null
                    ? null
                    : _stops
                          .where((s) => s['name'] == _destinationName)
                          .map(
                            (s) =>
                                '${s['name']}:${(s['location'] as LatLng).latitude}:${(s['location'] as LatLng).longitude}',
                          )
                          .firstOrNull,
                items: _stops.map((stop) {
                  final p = stop['location'] as LatLng;
                  return DropdownMenuItem(
                    value: '${stop['name']}:${p.latitude}:${p.longitude}',
                    child: Text(stop['name'].toString()),
                  );
                }).toList(),
                onChanged: (value) => _chooseStop(value, false),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Set Pickup'),
                      selected: _selectingPickup,
                      onSelected: (_) =>
                          setState(() => _selectingPickup = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Set Destination'),
                      selected: !_selectingPickup,
                      onSelected: (_) =>
                          setState(() => _selectingPickup = false),
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
                      label: Text(
                        _searching ? 'Searching...' : 'Search Available Buses',
                      ),
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
                        _pickupName = null;
                        _destinationName = null;
                        _hasSearched = false;
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
            polylines: _routeLines,
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
                        : _hasSearched
                        ? 'No active bus currently serves these stops.'
                        : 'Choose real route stops or tap the map, then search.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    final route = Map<String, dynamic>.from(
                      match['route'] ?? {},
                    );
                    final pickupStop = Map<String, dynamic>.from(
                      match['pickupStop'] ?? {},
                    );
                    final dropoffStop = Map<String, dynamic>.from(
                      match['dropoffStop'] ?? {},
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route ${route['routeNumber'] ?? match['routeId'] ?? '-'}: ${route['from'] ?? '-'} to ${route['to'] ?? '-'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Bus: ${match['vehicleId'] ?? 'Unknown'}'),
                            Text(
                              'Crowd: ${match['crowdLevel'] ?? 'unknown'} (${match['occupancy'] ?? 0})',
                            ),
                            Text(
                              match['etaMinutes'] == null
                                  ? 'Waiting for live GPS'
                                  : 'Pickup ETA: ${match['etaMinutes']} min',
                            ),
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
