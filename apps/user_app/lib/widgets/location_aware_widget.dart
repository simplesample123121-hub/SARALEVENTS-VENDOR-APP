import 'package:flutter/material.dart';
import '../core/services/permission_service.dart';
import '../core/services/location_service.dart';
import '../core/widgets/permission_manager.dart';
import 'package:geolocator/geolocator.dart';

/// Widget that provides location-aware functionality
class LocationAwareWidget extends StatefulWidget {
  final Widget Function(BuildContext context, Position? position, bool hasPermission) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final bool requestPermissionOnInit;
  final bool showPermissionDialog;

  const LocationAwareWidget({
    super.key,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.requestPermissionOnInit = true,
    this.showPermissionDialog = true,
  });

  @override
  State<LocationAwareWidget> createState() => _LocationAwareWidgetState();
}

class _LocationAwareWidgetState extends State<LocationAwareWidget> 
    with LocationPermissionMixin {
  Position? _position;
  bool _hasPermission = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.requestPermissionOnInit) {
      _initializeLocation();
    } else {
      _checkPermissionOnly();
    }
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check permission first
      _hasPermission = await hasLocationPermission();
      
      if (!_hasPermission && widget.showPermissionDialog) {
        _hasPermission = await requestLocationPermission();
      }

      if (_hasPermission) {
        _position = await LocationService.getCurrentPosition();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkPermissionOnly() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _hasPermission = await hasLocationPermission();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ?? 
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ?? 
          Center(child: Text('Error: $_error'));
    }

    return widget.builder(context, _position, _hasPermission);
  }
}

/// Widget that shows different content based on location permission status
class LocationPermissionGate extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext context, LocationPermissionStatus status)? fallbackBuilder;
  final bool showFallbackForDenied;

  const LocationPermissionGate({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.showFallbackForDenied = true,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionStatusWidget(
      builder: (context, status) {
        if (status == LocationPermissionStatus.granted) {
          return child;
        }

        if (showFallbackForDenied && fallbackBuilder != null) {
          return fallbackBuilder!(context, status);
        }

        return child;
      },
    );
  }
}

/// Mixin for widgets that need location functionality
mixin LocationAwareMixin<T extends StatefulWidget> on State<T> {
  Position? _currentPosition;
  bool _hasLocationPermission = false;

  Position? get currentPosition => _currentPosition;
  bool get hasLocationPermission => _hasLocationPermission;

  Future<void> initializeLocation({bool requestPermission = true}) async {
    try {
      if (requestPermission) {
        _hasLocationPermission = await _requestLocationPermission();
      } else {
        _hasLocationPermission = await _checkLocationPermission();
      }

      if (_hasLocationPermission) {
        _currentPosition = await LocationService.getCurrentPosition();
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  Future<bool> _requestLocationPermission() async {
    final result = await PermissionService.requestLocationPermission(
      context: context,
      showRationale: true,
    );
    return result.isGranted;
  }

  Future<bool> _checkLocationPermission() async {
    final status = await PermissionService.getLocationPermissionStatus();
    return status == LocationPermissionStatus.granted;
  }

  Future<void> refreshLocation() async {
    if (_hasLocationPermission) {
      try {
        _currentPosition = await LocationService.getCurrentPosition();
      } catch (e) {
        debugPrint('Error refreshing location: $e');
      }
    }
  }

  double? distanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }
}

/// Widget that shows distance to a location
class DistanceWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final TextStyle? textStyle;
  final IconData? icon;
  final Color? iconColor;

  const DistanceWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.textStyle,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return LocationAwareWidget(
      requestPermissionOnInit: false,
      showPermissionDialog: false,
      builder: (context, position, hasPermission) {
        if (!hasPermission || position == null) {
          return const SizedBox.shrink();
        }

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          latitude,
          longitude,
        );

        final formattedDistance = distance < 1000
            ? '${distance.round()}m'
            : '${(distance / 1000).toStringAsFixed(1)}km';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor ?? Colors.grey,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              formattedDistance,
              style: textStyle ?? const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
      loadingBuilder: (context) => const SizedBox.shrink(),
      errorBuilder: (context, error) => const SizedBox.shrink(),
    );
  }
}