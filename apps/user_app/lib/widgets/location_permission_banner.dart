import 'package:flutter/material.dart';
import '../core/services/permission_service.dart';
import '../core/widgets/permission_manager.dart';

/// Banner widget that shows location permission status and allows user to enable it
class LocationPermissionBanner extends StatefulWidget {
  final bool showWhenGranted;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const LocationPermissionBanner({
    super.key,
    this.showWhenGranted = false,
    this.margin,
    this.padding,
  });

  @override
  State<LocationPermissionBanner> createState() => _LocationPermissionBannerState();
}

class _LocationPermissionBannerState extends State<LocationPermissionBanner> 
    with LocationPermissionMixin {
  
  @override
  Widget build(BuildContext context) {
    return PermissionStatusWidget(
      builder: (context, status) {
        // Don't show banner if permission is granted and showWhenGranted is false
        if (status == LocationPermissionStatus.granted && !widget.showWhenGranted) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: widget.margin ?? const EdgeInsets.all(16),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(status),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(status),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                PermissionUtils.getPermissionStatusIcon(status),
                color: _getIconColor(status),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTitle(status),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _getTextColor(status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMessage(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTextColor(status).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_shouldShowAction(status)) ...[
                const SizedBox(width: 12),
                _buildActionButton(status),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return Colors.green.shade50;
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.notRequested:
        return Colors.blue.shade50;
      case LocationPermissionStatus.permanentlyDenied:
      case LocationPermissionStatus.serviceDisabled:
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getBorderColor(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return Colors.green.shade200;
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.notRequested:
        return Colors.blue.shade200;
      case LocationPermissionStatus.permanentlyDenied:
      case LocationPermissionStatus.serviceDisabled:
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getIconColor(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return Colors.green.shade600;
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.notRequested:
        return Colors.blue.shade600;
      case LocationPermissionStatus.permanentlyDenied:
      case LocationPermissionStatus.serviceDisabled:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getTextColor(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return Colors.green.shade800;
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.notRequested:
        return Colors.blue.shade800;
      case LocationPermissionStatus.permanentlyDenied:
      case LocationPermissionStatus.serviceDisabled:
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _getTitle(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return 'Location Access Enabled';
      case LocationPermissionStatus.denied:
        return 'Location Access Denied';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Location Permission Required';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location Services Disabled';
      case LocationPermissionStatus.notRequested:
        return 'Enable Location Access';
      default:
        return 'Location Status Unknown';
    }
  }

  String _getMessage(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return 'We can show you events and services near your location.';
      case LocationPermissionStatus.denied:
        return 'Allow location access to find events and services near you.';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Please enable location access in app settings to use location features.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Please enable location services in your device settings.';
      case LocationPermissionStatus.notRequested:
        return 'Get personalized recommendations based on your location.';
      default:
        return 'Location permission status is unclear.';
    }
  }

  bool _shouldShowAction(LocationPermissionStatus status) {
    return status != LocationPermissionStatus.granted;
  }

  Widget _buildActionButton(LocationPermissionStatus status) {
    String buttonText;
    VoidCallback? onPressed;

    switch (status) {
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.notRequested:
        buttonText = 'Allow';
        onPressed = () async {
          await requestLocationPermission();
        };
        break;
      case LocationPermissionStatus.permanentlyDenied:
        buttonText = 'Settings';
        onPressed = () async {
          await PermissionService.showPermissionDeniedDialog(context, status);
        };
        break;
      case LocationPermissionStatus.serviceDisabled:
        buttonText = 'Enable';
        onPressed = () async {
          await PermissionService.showPermissionDeniedDialog(context, status);
        };
        break;
      default:
        buttonText = 'Retry';
        onPressed = () async {
          await requestLocationPermission();
        };
        break;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getIconColor(status),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(buttonText),
    );
  }
}

/// Compact location permission indicator for app bars
class LocationPermissionIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const LocationPermissionIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionStatusWidget(
      builder: (context, status) {
        if (status == LocationPermissionStatus.granted) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap ?? () => _showPermissionDialog(context, status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PermissionUtils.getPermissionStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PermissionUtils.getPermissionStatusColor(status).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PermissionUtils.getPermissionStatusIcon(status),
                  size: 16,
                  color: PermissionUtils.getPermissionStatusColor(status),
                ),
                const SizedBox(width: 4),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PermissionUtils.getPermissionStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPermissionDialog(BuildContext context, LocationPermissionStatus status) {
    PermissionService.showPermissionDeniedDialog(context, status);
  }
}