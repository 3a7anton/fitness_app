import 'dart:async';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fitness_flutter/core/service/location_tracking_service.dart';
import 'package:flutter/material.dart';

class MapsService {
  static Completer<GoogleMapController>? _controller;
  static Set<Marker> _markers = {};
  static Set<Polyline> _polylines = {};
  static LatLng? _currentPosition;

  /// Initialize Google Maps
  static void initializeMap(GoogleMapController controller) {
    _controller = Completer<GoogleMapController>();
    _controller!.complete(controller);
  }

  /// Update current position marker
  static Future<void> updateCurrentPosition(LatLng position) async {
    _currentPosition = position;
    
    _markers.removeWhere((marker) => marker.markerId.value == 'current_position');
    
    _markers.add(
      Marker(
        markerId: const MarkerId('current_position'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Current Location',
          snippet: 'You are here',
        ),
      ),
    );
  }

  /// Add route polyline to map
  static void addRoutePolyline(List<LocationPoint> routePoints, {String routeId = 'current_route'}) {
    if (routePoints.isEmpty) return;

    final polylinePoints = routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    _polylines.removeWhere((polyline) => polyline.polylineId.value == routeId);

    _polylines.add(
      Polyline(
        polylineId: PolylineId(routeId),
        points: polylinePoints,
        color: Colors.blue,
        width: 4,
        patterns: [],
      ),
    );
  }

  /// Add start and end markers for a route
  static void addRouteMarkers(RouteData route) {
    if (route.points.isEmpty) return;

    final startPoint = route.points.first;
    final endPoint = route.points.last;

    // Add start marker
    _markers.add(
      Marker(
        markerId: MarkerId('route_start_${route.id}'),
        position: LatLng(startPoint.latitude, startPoint.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Start',
          snippet: 'Started at ${route.startTime.toString().substring(11, 16)}',
        ),
      ),
    );

    // Add end marker
    _markers.add(
      Marker(
        markerId: MarkerId('route_end_${route.id}'),
        position: LatLng(endPoint.latitude, endPoint.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Finish',
          snippet: 'Finished at ${route.endTime.toString().substring(11, 16)}',
        ),
      ),
    );
  }

  /// Center map on current position
  static Future<void> centerOnCurrentPosition() async {
    if (_controller == null || _currentPosition == null) return;

    final GoogleMapController controller = await _controller!.future;
    await controller.animateCamera(
      CameraUpdate.newLatLng(_currentPosition!),
    );
  }

  /// Center map on route
  static Future<void> centerOnRoute(List<LocationPoint> routePoints) async {
    if (_controller == null || routePoints.isEmpty) return;

    final GoogleMapController controller = await _controller!.future;

    // Calculate bounds
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Add padding
    const padding = 0.001;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  /// Clear all markers
  static void clearMarkers() {
    _markers.clear();
  }

  /// Clear all polylines
  static void clearPolylines() {
    _polylines.clear();
  }

  /// Clear everything
  static void clearAll() {
    _markers.clear();
    _polylines.clear();
  }

  /// Get current markers
  static Set<Marker> get markers => _markers;

  /// Get current polylines
  static Set<Polyline> get polylines => _polylines;

  /// Add custom marker
  static void addCustomMarker({
    required String id,
    required LatLng position,
    required String title,
    String? snippet,
    BitmapDescriptor? icon,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        icon: icon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
      ),
    );
  }

  /// Remove marker by ID
  static void removeMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
  }

  /// Get distance between two points
  static double getDistanceBetween(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = point1.latitude * (3.141592653589793 / 180);
    double lat2Rad = point2.latitude * (3.141592653589793 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.141592653589793 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.141592653589793 / 180);

    double a = (sin(deltaLatRad / 2) * sin(deltaLatRad / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Create default map options
  static MapType getDefaultMapType() => MapType.normal;

  /// Get initial camera position
  static CameraPosition getInitialCameraPosition({LatLng? position}) {
    return CameraPosition(
      target: position ?? const LatLng(37.7749, -122.4194), // Default to San Francisco
      zoom: 15.0,
    );
  }

  /// Show route summary info window
  static void showRouteSummary(RouteData route) {
    if (route.points.isEmpty) return;

    final midPointIndex = route.points.length ~/ 2;
    final midPoint = route.points[midPointIndex];

    _markers.add(
      Marker(
        markerId: MarkerId('route_summary_${route.id}'),
        position: LatLng(midPoint.latitude, midPoint.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
          title: route.name,
          snippet: 'Distance: ${route.totalDistance.toStringAsFixed(2)} km\n'
                  'Duration: ${route.duration.inMinutes} min\n'
                  'Avg Speed: ${route.averageSpeed.toStringAsFixed(1)} km/h',
        ),
      ),
    );
  }
}

// Helper functions for trigonometry
double sin(double x) => math.sin(x);
double cos(double x) => math.cos(x);
double sqrt(double x) => math.sqrt(x);
double atan2(double y, double x) => math.atan2(y, x);
