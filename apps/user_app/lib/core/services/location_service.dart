import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart' as geo;

class LocationService {
  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  static Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Get a fresh, best-effort position by listening briefly to the live stream
  static Future<Position> getFreshPosition({Duration timeout = const Duration(seconds: 6)}) async {
    // Start with last known, then prefer the newest from stream within timeout
    Position? best = await Geolocator.getLastKnownPosition();
    late StreamSubscription<Position> sub;
    final completer = Completer<Position>();
    try {
      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
      ).listen((pos) {
        best = pos;
      });
      // Wait for timeout then resolve with best available (or fall back to current)
      await Future.delayed(timeout);
      if (best != null) {
        completer.complete(best!);
      } else {
        final current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        completer.complete(current);
      }
    } finally {
      await sub.cancel();
    }
    return completer.future;
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final list = await geo.placemarkFromCoordinates(lat, lng);
    if (list.isEmpty) return null;
    final p = list.first;
    return [p.name, p.subLocality, p.locality, p.administrativeArea, p.postalCode]
        .where((e) => e != null && e!.isNotEmpty)
        .map((e) => e!)
        .join(', ');
  }
}


