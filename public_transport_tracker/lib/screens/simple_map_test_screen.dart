import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SimpleMapTestScreen extends StatelessWidget {
  const SimpleMapTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Default location (Chennai, India - you can change this to your city)
    const LatLng center = LatLng(13.0827, 80.2707);

    return Scaffold(
      appBar: AppBar(
        title: Text('Map Test - FREE!'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.0,
            // Add interaction options to prevent layout issues
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Try CartoDB tiles first (usually work best on web)
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              maxZoom: 18,
            ),
          
          // Add a simple marker
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "tile1",
            mini: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Using CartoDB tiles - should work on web!')),
              );
            },
            child: Text('1', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.blue,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "info",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Map Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Map Type: OpenStreetMap'),
                      Text('✅ Tiles: CartoDB (Free)'),
                      Text('✅ Cost: \$0 - Completely FREE!'),
                      Text('✅ API Key: Not required'),
                      SizedBox(height: 8),
                      Text('If you see this map clearly, your setup is working!'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: Icon(Icons.info),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }
}