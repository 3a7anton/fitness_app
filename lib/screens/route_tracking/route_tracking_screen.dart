import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/location_tracking_service.dart';
import 'package:fitness_flutter/core/service/maps_service.dart';

class RouteTrackingScreen extends StatefulWidget {
  const RouteTrackingScreen({Key? key}) : super(key: key);

  @override
  _RouteTrackingScreenState createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  GoogleMapController? _mapController;
  bool _isTracking = false;
  Timer? _updateTimer;
  RouteData? _currentRoute;
  
  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    await LocationTrackingService.initialize();
    final isTracking = await LocationTrackingService.getTrackingState();
    
    setState(() {
      _isTracking = isTracking;
    });

    if (_isTracking) {
      _startTrackingUI();
    }
  }

  void _startTrackingUI() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateRouteOnMap();
    });
  }

  void _stopTrackingUI() {
    _updateTimer?.cancel();
  }

  Future<void> _updateRouteOnMap() async {
    final currentRoute = LocationTrackingService.getCurrentRouteData();
    if (currentRoute != null && mounted) {
      setState(() {
        _currentRoute = currentRoute;
      });

      // Update map with current route
      MapsService.addRoutePolyline(currentRoute.points);
      
      if (currentRoute.points.isNotEmpty) {
        final lastPoint = currentRoute.points.last;
        MapsService.updateCurrentPosition(
          LatLng(lastPoint.latitude, lastPoint.longitude),
        );
      }
    }
  }

  Future<void> _startTracking() async {
    final success = await LocationTrackingService.startRouteTracking();
    if (success) {
      setState(() {
        _isTracking = true;
      });
      _startTrackingUI();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route tracking started')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start tracking')),
      );
    }
  }

  Future<void> _stopTracking() async {
    final route = await LocationTrackingService.stopRouteTracking();
    setState(() {
      _isTracking = false;
    });
    _stopTrackingUI();

    if (route != null) {
      _showRouteSummaryDialog(route);
    }
  }

  void _showRouteSummaryDialog(RouteData route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${route.totalDistance.toStringAsFixed(2)} km'),
            Text('Duration: ${route.duration.inMinutes} minutes'),
            Text('Average Speed: ${route.averageSpeed.toStringAsFixed(1)} km/h'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Route Tracking',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              MapsService.initializeMap(controller);
            },
            initialCameraPosition: MapsService.getInitialCameraPosition(),
            mapType: MapsService.getDefaultMapType(),
            markers: MapsService.markers,
            polylines: MapsService.polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          _buildTrackingControls(),
          if (_isTracking && _currentRoute != null) _buildTrackingStats(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        backgroundColor: _isTracking ? Colors.red : ColorConstants.primaryColor,
        child: Icon(
          _isTracking ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'center',
            onPressed: () async {
              final currentLocation = await LocationTrackingService.getCurrentLocation();
              if (currentLocation != null) {
                MapsService.updateCurrentPosition(
                  LatLng(currentLocation.latitude, currentLocation.longitude),
                );
                MapsService.centerOnCurrentPosition();
              }
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.black),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            mini: true,
            heroTag: 'clear',
            onPressed: () {
              MapsService.clearAll();
              setState(() {});
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.clear, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStats() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Distance',
                  '${_currentRoute!.totalDistance.toStringAsFixed(2)} km',
                  Icons.straighten,
                ),
                _buildStatItem(
                  'Duration',
                  '${_currentRoute!.duration.inMinutes}:${(_currentRoute!.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  Icons.timer,
                ),
                _buildStatItem(
                  'Speed',
                  '${_currentRoute!.averageSpeed.toStringAsFixed(1)} km/h',
                  Icons.speed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ColorConstants.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
