import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  // Check permission and get current position
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  // Simple Geofence check (Simulated for now as we don't have ward polygons)
  // In a real app, we would check if point is inside a Polygon.
  // For this MVP, we will assume true if location is retrieved.
  static bool isWithinWard(Position position, String wardId) {
    // TODO: Implement actual polygon check
    return true; 
  }
}
