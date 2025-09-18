import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive permission management service
class PermissionService {
  static const String _locationPermissionAskedKey = 'location_permission_asked';
  static const String _locationPermissionDeniedKey = 'location_permission_denied';
  static const String _appFirstLaunchKey = 'app_first_launch';

  /// Check if this is the first app launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_appFirstLaunchKey);
  }

  /// Mark app as launched
  static Future<void> markAppLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appFirstLaunchKey, false);
  }

  /// Check if location permission was previously asked
  static Future<bool> wasLocationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionAskedKey) ?? false;
  }

  /// Mark location permission as asked
  static Future<void> markLocationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionAskedKey, true);
  }

  /// Check if location permission was permanently denied
  static Future<bool> wasLocationPermissionDenied() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionDeniedKey) ?? false;
  }

  /// Mark location permission as denied
  static Future<void> markLocationPermissionDenied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionDeniedKey, true);
  }

  /// Clear location permission denial status
  static Future<void> clearLocationPermissionDenied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationPermissionDeniedKey);
  }

  /// Get current location permission status
  static Future<LocationPermissionStatus> getLocationPermissionStatus() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    // Check permission status
    final permission = await Permission.location.status;
    
    switch (permission) {
      case PermissionStatus.granted:
        return LocationPermissionStatus.granted;
      case PermissionStatus.denied:
        final wasAsked = await wasLocationPermissionAsked();
        return wasAsked 
            ? LocationPermissionStatus.denied 
            : LocationPermissionStatus.notRequested;
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return LocationPermissionStatus.restricted;
      case PermissionStatus.limited:
        return LocationPermissionStatus.limited;
      case PermissionStatus.provisional:
        return LocationPermissionStatus.provisional;
    }
  }

  /// Request location permission with proper flow
  static Future<LocationPermissionResult> requestLocationPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult(
          status: LocationPermissionStatus.serviceDisabled,
          shouldShowRationale: false,
        );
      }

      // Check current status
      final currentStatus = await getLocationPermissionStatus();
      
      // If already granted, return success
      if (currentStatus == LocationPermissionStatus.granted) {
        return LocationPermissionResult(
          status: LocationPermissionStatus.granted,
          shouldShowRationale: false,
        );
      }

      // If permanently denied, guide to settings
      if (currentStatus == LocationPermissionStatus.permanentlyDenied) {
        return LocationPermissionResult(
          status: LocationPermissionStatus.permanentlyDenied,
          shouldShowRationale: true,
        );
      }

      // Show rationale if needed and context is provided
      if (showRationale && context != null && currentStatus == LocationPermissionStatus.denied) {
        final shouldProceed = await _showLocationRationale(context);
        if (!shouldProceed) {
          return LocationPermissionResult(
            status: LocationPermissionStatus.denied,
            shouldShowRationale: false,
          );
        }
      }

      // Mark as asked
      await markLocationPermissionAsked();

      // Request permission
      final result = await Permission.location.request();
      
      switch (result) {
        case PermissionStatus.granted:
          await clearLocationPermissionDenied();
          return LocationPermissionResult(
            status: LocationPermissionStatus.granted,
            shouldShowRationale: false,
          );
        case PermissionStatus.denied:
          await markLocationPermissionDenied();
          return LocationPermissionResult(
            status: LocationPermissionStatus.denied,
            shouldShowRationale: true,
          );
        case PermissionStatus.permanentlyDenied:
          await markLocationPermissionDenied();
          return LocationPermissionResult(
            status: LocationPermissionStatus.permanentlyDenied,
            shouldShowRationale: true,
          );
        default:
          return LocationPermissionResult(
            status: LocationPermissionStatus.denied,
            shouldShowRationale: false,
          );
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermissionResult(
        status: LocationPermissionStatus.denied,
        shouldShowRationale: false,
      );
    }
  }

  /// Show location permission rationale dialog
  static Future<bool> _showLocationRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('Location Access'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saral Events needs location access to:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              _PermissionReasonItem(
                icon: Icons.near_me,
                text: 'Find events and services near you',
              ),
              _PermissionReasonItem(
                icon: Icons.map,
                text: 'Show your location on maps',
              ),
              _PermissionReasonItem(
                icon: Icons.directions,
                text: 'Provide accurate directions',
              ),
              _PermissionReasonItem(
                icon: Icons.local_offer,
                text: 'Show location-based offers',
              ),
              SizedBox(height: 12),
              Text(
                'Your location data is kept private and secure.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show permission denied dialog with options
  static Future<void> showPermissionDeniedDialog(
    BuildContext context,
    LocationPermissionStatus status,
  ) async {
    String title;
    String message;
    String actionText;
    VoidCallback? action;

    switch (status) {
      case LocationPermissionStatus.serviceDisabled:
        title = 'Location Services Disabled';
        message = 'Please enable location services in your device settings to use location features.';
        actionText = 'Open Settings';
        action = () async => await Geolocator.openLocationSettings();
        break;
      case LocationPermissionStatus.permanentlyDenied:
        title = 'Location Permission Required';
        message = 'Location access has been permanently denied. Please enable it in app settings to use location features.';
        actionText = 'Open Settings';
        action = () async => await openAppSettings();
        break;
      case LocationPermissionStatus.denied:
        title = 'Location Access Denied';
        message = 'Location access is required to find events and services near you. You can enable it later in settings.';
        actionText = 'Try Again';
        action = () async {
          Navigator.of(context).pop();
          await requestLocationPermission(context: context);
        };
        break;
      default:
        return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.orange),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (action != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  action!();
                },
                child: Text(actionText),
              ),
          ],
        );
      },
    );
  }

  /// Initialize permissions on app start
  static Future<void> initializePermissions(BuildContext context) async {
    final isFirstLaunch = await PermissionService.isFirstLaunch();
    
    if (isFirstLaunch) {
      await markAppLaunched();
      
      // Show welcome dialog with permission explanation
      await _showWelcomePermissionDialog(context);
      
      // Request location permission
      await requestLocationPermission(context: context);
    } else {
      // Check if we should prompt for location permission
      final status = await getLocationPermissionStatus();
      if (status == LocationPermissionStatus.notRequested) {
        await requestLocationPermission(context: context, showRationale: false);
      }
    }
  }

  /// Show welcome dialog explaining permissions
  static Future<void> _showWelcomePermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.waving_hand, color: Colors.orange),
              SizedBox(width: 8),
              Text('Welcome to Saral Events!'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To provide you with the best experience, we\'ll need access to your location.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'This helps us:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              _PermissionReasonItem(
                icon: Icons.event,
                text: 'Show events happening near you',
              ),
              _PermissionReasonItem(
                icon: Icons.business,
                text: 'Find the best local service providers',
              ),
              _PermissionReasonItem(
                icon: Icons.navigation,
                text: 'Provide accurate directions',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for showing permission reason items
class _PermissionReasonItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PermissionReasonItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Location permission status enum
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  notRequested,
  serviceDisabled,
}

/// Location permission result
class LocationPermissionResult {
  final LocationPermissionStatus status;
  final bool shouldShowRationale;

  const LocationPermissionResult({
    required this.status,
    required this.shouldShowRationale,
  });

  bool get isGranted => status == LocationPermissionStatus.granted;
  bool get isDenied => status == LocationPermissionStatus.denied;
  bool get isPermanentlyDenied => status == LocationPermissionStatus.permanentlyDenied;
  bool get isServiceDisabled => status == LocationPermissionStatus.serviceDisabled;
}