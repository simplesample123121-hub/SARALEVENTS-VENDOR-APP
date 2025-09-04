import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleAppUpdateService {
  // App Store URLs - Replace with your actual URLs
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.saral_events_vendor_app';
  static const String _appStoreUrl = 'https://apps.apple.com/app/id123456789';
  
  // SharedPreferences keys
  static const String _lastShownDateKey = 'last_update_shown_date';
  static constString _updateCheckCountKey = 'update_check_count';
  
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
      // final response = await http.get(Uri.parse('https://your-backend.com/api/latest-version'));
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
    
    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
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
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s New:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Improved performance and stability\n• New user interface design\n• Bug fixes and security updates\n• Enhanced event management features',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Skip button
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
                  _performUpdate();
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
  
  /// Perform the update by redirecting to store
  static Future<void> _performUpdate() async {
    try {
      if (Platform.isAndroid) {
        // Redirect to Play Store
        final Uri url = Uri.parse(_playStoreUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        // Redirect to App Store
        final Uri url = Uri.parse(_appStoreUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error launching store: $e');
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
      
      // Increment check count
      int checkCount = prefs.getInt(_updateCheckCountKey) ?? 0;
      await prefs.setInt(_updateCheckCountKey, checkCount + 1);
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
  
  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting version: $e');
      return 'Unknown';
    }
  }
  
  /// Get app build number
  static Future<String> getBuildNumber() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Error getting build number: $e');
      return 'Unknown';
    }
  }
  
  /// Reset update tracking (useful for testing)
  static Future<void> resetUpdateTracking() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastShownDateKey);
      await prefs.remove(_updateCheckCountKey);
    } catch (e) {
      debugPrint('Error resetting update tracking: $e');
    }
  }
}
