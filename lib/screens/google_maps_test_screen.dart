import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsTestScreen extends StatefulWidget {
  const GoogleMapsTestScreen({Key? key}) : super(key: key);

  @override
  State<GoogleMapsTestScreen> createState() => _GoogleMapsTestScreenState();
}

class _GoogleMapsTestScreenState extends State<GoogleMapsTestScreen> {
  late GoogleMapController mapController;

  // Default location: Sydney, Australia (as per Google documentation)
  final LatLng _center = const LatLng(-33.86, 151.20);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Test'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If you see a map below, your Google Maps API key is working!',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId('sydney'),
                  position: _center,
                  infoWindow: const InfoWindow(
                    title: 'Sydney Opera House',
                    snippet: 'Test marker for Google Maps',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.green.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Google Maps Setup Checklist:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('✅ Google Maps Flutter package installed'),
                const Text('✅ Secrets Gradle Plugin configured'),
                const Text('✅ AndroidManifest.xml updated'),
                const Text('✅ Location permissions added'),
                const Text('⚠️ Add your API key to secrets.properties'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
