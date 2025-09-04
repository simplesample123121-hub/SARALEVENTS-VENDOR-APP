import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class AppUpdateService {
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=';
  static const String _appStoreUrl = 'https://apps.apple.com/app/id';
  
  // You can store this in your backend or config
  static const String _latestVersionUrl = 'https://your-backend.com/api/latest-version';
  
  // SharedPreferences keys
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _updateShownTodayKey = 'update_shown_today';
  static const String _lastShownDateKey = 'last_shown_date';
  
  /// Check for app updates and show appropriate dialog
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      // Check if update is available (you can implement your own logic here)
      bool updateAvailable = await _isUpdateAvailable(currentVersion);
      
      if (updateAvailable) {
        // Show update dialog
        _showUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }
  
  /// Check if update is available
  static Future<bool> _isUpdateAvailable(String currentVersion) async {
    try {
      // Option 1: Check against your backend API
      // final response = await http.get(Uri.parse(_latestVersionUrl));
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return _compareVersions(currentVersion, data['version']);
      // }
      
      // Option 2: Simple version comparison (you can customize this)
      // For now, we'll show update dialog on every app launch for demo
      // In production, implement proper version checking logic
      return true;
      
    } catch (e) {
      debugPrint('Error checking update availability: $e');
      return false;
    }
  }
  
  /// Compare version strings
  static bool _compareVersions(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < math.min(currentParts.length, latestParts.length); i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    
    return latestParts.length > currentParts.length;
  }
  
  /// Show update dialog
  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button from closing dialog
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: Colors.blue,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Update Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version of Saral Events Vendor App is available!',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Update now to get the latest features and improvements.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              // Skip button (optional)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markUpdateShown();
                },
                child: Text(
                  'Later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              // Update button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performUpdate(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Update Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Perform the update based on platform
  static Future<void> _performUpdate(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        // Try in-app update first
        await _tryInAppUpdate();
      } else if (Platform.isIOS) {
        // For iOS, redirect to App Store
        _redirectToStore();
      }
    } catch (e) {
      debugPrint('Error performing update: $e');
      // Fallback to store redirect
      _redirectToStore();
    }
  }
  
  /// Try in-app update for Android
  static Future<void> _tryInAppUpdate() async {
    try {
      // Check if in-app update is available
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          // Perform immediate update
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Perform flexible update
          await InAppUpdate.startFlexibleUpdate();
        } else {
          // Fallback to store redirect
          _redirectToStore();
        }
      } else {
        // No update available, redirect to store
        _redirectToStore();
      }
    } catch (e) {
      debugPrint('In-app update failed: $e');
      _redirectToStore();
    }
  }
  
  /// Redirect to appropriate app store
  static void _redirectToStore() {
    if (Platform.isAndroid) {
      // Replace with your actual package name
      StoreRedirect.redirect(
        androidAppId: 'com.example.saral_events_vendor_app',
        iOSAppId: 'your_ios_app_id',
      );
    } else if (Platform.isIOS) {
      // Replace with your actual iOS app ID
      StoreRedirect.redirect(
        androidAppId: 'com.example.saral_events_vendor_app',
        iOSAppId: 'your_ios_app_id',
      );
    }
  }
  
  /// Check for updates on app startup
  static Future<void> checkOnStartup(BuildContext context) async {
    // Wait a bit for the app to fully load
    await Future.delayed(Duration(seconds: 2));
    
    // Check if user has already seen the update dialog today
    if (!await _hasShownUpdateToday()) {
      await checkForUpdates(context);
    }
  }
  
  /// Check if update dialog was shown today
  static Future<bool> _hasShownUpdateToday() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? lastShownDate = prefs.getString(_lastShownDateKey);
      
      if (lastShownDate == null) {
        return false;
      }
      
      DateTime lastShown = DateTime.parse(lastShownDate);
      DateTime now = DateTime.now();
      
      // Check if it's the same day
      return lastShown.year == now.year &&
             lastShown.month == now.month &&
             lastShown.day == now.day;
    } catch (e) {
      debugPrint('Error checking update shown status: $e');
      return false;
    }
  }
  
  /// Mark that update dialog was shown
  static Future<void> _markUpdateShown() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastShownDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking update as shown: $e');
    }
  }
  
  /// Force check for updates (can be called from settings or menu)
  static Future<void> forceCheckForUpdates(BuildContext context) async {
    await checkForUpdates(context);
  }
  
  /// Check if app is running the latest version
  static Future<bool> isLatestVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      // Implement your version checking logic here
      // For now, return true (you can customize this)
      return true;
    } catch (e) {
      debugPrint('Error checking version: $e');
      return false;
    }
  }
}
