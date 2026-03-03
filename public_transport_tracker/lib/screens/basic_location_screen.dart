import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class BasicLocationScreen extends StatefulWidget {
  const BasicLocationScreen({super.key});

  @override
  State<BasicLocationScreen> createState() => _BasicLocationScreenState();
}

class _BasicLocationScreenState extends State<BasicLocationScreen> {
  Location location = Location();
  String locationText = 'Getting location...';
  String addressText = 'Getting address...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            locationText = 'Location services are disabled.';
            isLoading = false;
          });
          return;
        }
      }

      // Check permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            locationText = 'Location permission denied.';
            isLoading = false;
          });
          return;
        }
      }

      // Get current location
      LocationData locationData = await location.getLocation();
      
      setState(() {
        locationText = 
          'Latitude: ${locationData.latitude?.toStringAsFixed(6)}\n'
          'Longitude: ${locationData.longitude?.toStringAsFixed(6)}\n'
          'Accuracy: ${locationData.accuracy?.toStringAsFixed(1)}m';
        isLoading = false;
      });

      // Try to get address (reverse geocoding would need additional package)
      setState(() {
        addressText = 'Address lookup available with geocoding package';
      });

    } catch (e) {
      setState(() {
        locationText = 'Error getting location: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Location (No Maps)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                locationText = 'Getting location...';
              });
              _getCurrentLocation();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (isLoading)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Getting your location...'),
                        ],
                      )
                    else
                      Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Address Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(addressText),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'GPS Features Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('✅ Real-time GPS coordinates'),
                    Text('✅ Location accuracy measurement'),
                    Text('✅ Location permissions handled'),
                    Text('✅ Works on web & mobile'),
                    Text('✅ No API keys required'),
                    Text('✅ Completely FREE'),
                    SizedBox(height: 8),
                    Text(
                      'This shows your real GPS location without map rendering issues!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.my_location),
                label: Text('Update Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}