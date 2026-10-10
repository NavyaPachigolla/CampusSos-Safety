import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position? position;
  final String? errorMessage;
  final bool isPermissionDenied;

  const LocationResult({
    this.position,
    this.errorMessage,
    this.isPermissionDenied = false,
  });

  bool get hasLocation => position != null;
  double? get latitude => position?.latitude;
  double? get longitude => position?.longitude;

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return '';
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check whether location services are enabled and permissions are granted
  Future<bool> hasPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Request permissions and get the current user position safely
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Check if device location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          errorMessage:
              'Device location is disabled. Please turn on GPS / Location.',
        );
      }

      // 2. Check current permission status
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            errorMessage: 'Location permissions are denied.',
            isPermissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          errorMessage:
              'Location permissions are permanently denied. Please enable them in app settings.',
          isPermissionDenied: true,
        );
      }

      // 3. Fetch position with timeout and fallback to last known
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
        return LocationResult(position: position);
      } catch (timeoutOrError) {
        debugPrint('High accuracy location timed out, checking last known: $timeoutOrError');
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return LocationResult(position: lastKnown);
        }
        return LocationResult(
          errorMessage:
              'Unable to determine accurate location: ${timeoutOrError.toString()}',
        );
      }
    } catch (e) {
      return LocationResult(
        errorMessage: 'Location service error: ${e.toString()}',
      );
    }
  }

  /// Helper to generate Google Maps link for a coordinate
  static String makeMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
}
