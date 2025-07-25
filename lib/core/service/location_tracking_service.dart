import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationTrackingService {
  static Location? _location;
  static bool _isTracking = false;
  static StreamSubscription<LocationData>? _locationSubscription;
  static List<LocationPoint> _currentRoute = [];
  static DateTime? _routeStartTime;
  static double _totalDistance = 0.0;
  
  static const String _routesKey = 'saved_routes';
  static const String _trackingKey = 'is_tracking';

  /// Initialize location service
  static Future<bool> initialize() async {
    try {
      _location = Location();
      
      // Check if location service is enabled
      bool serviceEnabled = await _location!.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location!.requestService();
        if (!serviceEnabled) {
          print('Location service not enabled');
          return false;
        }
      }

      // Check permissions
      PermissionStatus permissionGranted = await _location!.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location!.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permission not granted');
          return false;
        }
      }

      print('Location service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  /// Start route tracking
  static Future<bool> startRouteTracking() async {
    if (_isTracking || _location == null) return false;

    try {
      _currentRoute.clear();
      _totalDistance = 0.0;
      _routeStartTime = DateTime.now();
      _isTracking = true;

      // Save tracking state
      await _saveTrackingState(true);

      // Start listening to location changes
      _locationSubscription = _location!.onLocationChanged.listen(
        _onLocationUpdate,
        onError: _onLocationError,
      );

      print('Route tracking started');
      return true;
    } catch (e) {
      print('Error starting route tracking: $e');
      return false;
    }
  }

  /// Stop route tracking
  static Future<RouteData?> stopRouteTracking() async {
    if (!_isTracking) return null;

    try {
      _isTracking = false;
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Save tracking state
      await _saveTrackingState(false);

      if (_currentRoute.isNotEmpty && _routeStartTime != null) {
        final routeData = RouteData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Route ${DateTime.now().toLocal().toString().substring(0, 16)}',
          startTime: _routeStartTime!,
          endTime: DateTime.now(),
          points: List.from(_currentRoute),
          totalDistance: _totalDistance,
          averageSpeed: _calculateAverageSpeed(),
        );

        // Save route
        await _saveRoute(routeData);
        
        print('Route tracking stopped. Distance: ${_totalDistance.toStringAsFixed(2)} km');
        return routeData;
      }

      return null;
    } catch (e) {
      print('Error stopping route tracking: $e');
      return null;
    }
  }

  /// Handle location updates
  static void _onLocationUpdate(LocationData locationData) {
    if (!_isTracking || locationData.latitude == null || locationData.longitude == null) {
      return;
    }

    final newPoint = LocationPoint(
      latitude: locationData.latitude!,
      longitude: locationData.longitude!,
      timestamp: DateTime.now(),
      altitude: locationData.altitude,
      speed: locationData.speed,
      accuracy: locationData.accuracy,
    );

    // Calculate distance from last point
    if (_currentRoute.isNotEmpty) {
      final lastPoint = _currentRoute.last;
      final distance = _calculateDistance(
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );
      
      // Only add point if moved significantly (> 5 meters)
      if (distance > 0.005) {
        _totalDistance += distance;
        _currentRoute.add(newPoint);
      }
    } else {
      _currentRoute.add(newPoint);
    }
  }

  /// Handle location errors
  static void _onLocationError(dynamic error) {
    print('Location tracking error: $error');
  }

  /// Get current location
  static Future<LocationPoint?> getCurrentLocation() async {
    if (_location == null) {
      await initialize();
    }

    try {
      final locationData = await _location!.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        return LocationPoint(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          timestamp: DateTime.now(),
          altitude: locationData.altitude,
          speed: locationData.speed,
          accuracy: locationData.accuracy,
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Save route to local storage
  static Future<void> _saveRoute(RouteData route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRoutes = await getSavedRoutes();
      existingRoutes.add(route);
      
      final routesJson = existingRoutes.map((r) => r.toJson()).toList();
      await prefs.setString(_routesKey, routesJson.toString());
    } catch (e) {
      print('Error saving route: $e');
    }
  }

  /// Get saved routes
  static Future<List<RouteData>> getSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesString = prefs.getString(_routesKey);
      
      if (routesString != null && routesString.isNotEmpty) {
        // Parse saved routes (implement proper JSON parsing)
        // For now, return empty list
        return [];
      }
      
      return [];
    } catch (e) {
      print('Error getting saved routes: $e');
      return [];
    }
  }

  /// Delete a saved route
  static Future<bool> deleteRoute(String routeId) async {
    try {
      final routes = await getSavedRoutes();
      routes.removeWhere((route) => route.id == routeId);
      
      final prefs = await SharedPreferences.getInstance();
      final routesJson = routes.map((r) => r.toJson()).toList();
      await prefs.setString(_routesKey, routesJson.toString());
      
      return true;
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }

  /// Calculate distance between two points (in kilometers)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Calculate average speed
  static double _calculateAverageSpeed() {
    if (_routeStartTime == null || _totalDistance == 0) return 0.0;
    
    final duration = DateTime.now().difference(_routeStartTime!);
    final hours = duration.inMilliseconds / (1000 * 60 * 60);
    
    return _totalDistance / hours; // km/h
  }

  /// Save tracking state
  static Future<void> _saveTrackingState(bool isTracking) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingKey, isTracking);
  }

  /// Get tracking state
  static Future<bool> getTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trackingKey) ?? false;
  }

  /// Get current route data
  static RouteData? getCurrentRouteData() {
    if (!_isTracking || _routeStartTime == null) return null;
    
    return RouteData(
      id: 'current',
      name: 'Current Route',
      startTime: _routeStartTime!,
      endTime: DateTime.now(),
      points: List.from(_currentRoute),
      totalDistance: _totalDistance,
      averageSpeed: _calculateAverageSpeed(),
    );
  }

  /// Check if currently tracking
  static bool get isTracking => _isTracking;
  
  /// Get current route points
  static List<LocationPoint> get currentRoute => List.from(_currentRoute);
  
  /// Get total distance
  static double get totalDistance => _totalDistance;
}

/// Location point class
class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
  final double? accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'altitude': altitude,
      'speed': speed,
      'accuracy': accuracy,
    };
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      altitude: json['altitude'],
      speed: json['speed'],
      accuracy: json['accuracy'],
    );
  }
}

/// Route data class
class RouteData {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final List<LocationPoint> points;
  final double totalDistance;
  final double averageSpeed;

  RouteData({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.points,
    required this.totalDistance,
    required this.averageSpeed,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
    };
  }

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      id: json['id'],
      name: json['name'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      points: (json['points'] as List).map((p) => LocationPoint.fromJson(p)).toList(),
      totalDistance: json['totalDistance'],
      averageSpeed: json['averageSpeed'],
    );
  }
}
