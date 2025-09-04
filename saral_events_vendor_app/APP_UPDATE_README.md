# App Update Notification System for Flutter

This implementation provides a comprehensive solution for notifying users about app updates in your Flutter application. It supports both Android and iOS platforms with different update strategies.

## Features

- ✅ **In-App Updates** (Android) - Seamless updates without leaving the app
- ✅ **Store Redirects** - Fallback to Play Store/App Store
- ✅ **Custom Update Dialogs** - Beautiful, branded update notifications
- ✅ **Smart Update Checking** - Prevents spam by tracking when dialogs were shown
- ✅ **Multiple Integration Options** - Easy to add to any screen
- ✅ **Configurable** - Easy to customize appearance and behavior
- ✅ **Platform Aware** - Different strategies for Android and iOS

## Installation

1. **Add Dependencies** (already added to pubspec.yaml):
```yaml
dependencies:
  in_app_update: ^0.2.0
  package_info_plus: ^8.0.2
  store_redirect: ^2.0.1
  shared_preferences: ^2.3.2
  http: ^1.2.2
```

2. **Run Flutter Pub Get**:
```bash
flutter pub get
```

## Quick Start

### Option 1: Automatic Integration (Recommended)

Wrap your `MaterialApp` with `AppUpdateWidget`:

```dart
import 'package:your_app/widgets/app_update_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppUpdateWidget(
      showOnInit: true,
      child: MaterialApp(
        title: 'Your App',
        home: HomePage(),
      ),
    );
  }
}
```

### Option 2: Manual Integration

Call the service directly in your screens:

```dart
import 'package:your_app/services/app_update_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Check for updates when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkOnStartup(context);
    });
  }
  
  // Manual update check
  void _checkForUpdates() {
    AppUpdateService.forceCheckForUpdates(context);
  }
}
```

## Configuration

### 1. Update App Store IDs

Edit `lib/config/app_update_config.dart`:

```dart
class AppUpdateConfig {
  // Replace with your actual app IDs
  static const String androidPackageName = 'com.yourcompany.yourapp';
  static const String iOSAppId = 'your_ios_app_id';
  
  // Customize behavior
  static const bool checkOnAppStart = true;
  static const bool forceUpdate = false;
  static const Duration startupDelay = Duration(seconds: 2);
}
```

### 2. Customize Update Dialog

```dart
// In app_update_config.dart
static const String dialogTitle = 'Update Available';
static const String dialogMessage = 'A new version is available!';
static const String updateButtonText = 'Update Now';
static const String skipButtonText = 'Later';
```

### 3. Customize Colors

```dart
// In app_update_config.dart
static const int primaryColor = 0xFF2196F3; // Blue
static const int accentColor = 0xFF1976D2; // Darker Blue
```

## Integration Options

### 1. Update Banner

Show a banner at the top of any screen:

```dart
import 'package:your_app/widgets/app_update_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UpdateBanner(
          onUpdatePressed: () {
            AppUpdateService.forceCheckForUpdates(context);
          },
          onDismiss: () {
            // Handle dismiss
          },
        ),
        // Your screen content
        Expanded(child: YourContent()),
      ],
    );
  }
}
```

### 2. Floating Action Button

Add a floating action button for updates:

```dart
import 'package:your_app/widgets/app_update_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YourContent(),
      floatingActionButton: UpdateFloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
```

### 3. App Bar Action

Add update button to app bar:

```dart
AppBar(
  title: Text('Your App'),
  actions: [
    IconButton(
      icon: Icon(Icons.system_update),
      onPressed: () {
        AppUpdateService.forceCheckForUpdates(context);
      },
      tooltip: 'Check for Updates',
    ),
  ],
)
```

## Advanced Features

### 1. Backend Version Checking

Implement your own version checking logic:

```dart
// In app_update_service.dart, modify _isUpdateAvailable method
static Future<bool> _isUpdateAvailable(String currentVersion) async {
  try {
    final response = await http.get(
      Uri.parse('https://your-api.com/latest-version'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _compareVersions(currentVersion, data['version']);
    }
    return false;
  } catch (e) {
    return false;
  }
}
```

### 2. Force Updates

Make updates mandatory:

```dart
// In app_update_config.dart
static const bool forceUpdate = true;

// In app_update_service.dart, modify dialog
static void _showUpdateDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // User cannot dismiss
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          // ... dialog content
          actions: [
            // Only show update button, no skip button
            ElevatedButton(
              onPressed: () => _performUpdate(context),
              child: Text('Update Now'),
            ),
          ],
        ),
      );
    },
  );
}
```

### 3. Custom Update Logic

Implement custom update strategies:

```dart
class CustomUpdateService {
  static Future<void> checkForCriticalUpdates(BuildContext context) async {
    // Check if current version has security vulnerabilities
    bool isCritical = await _checkSecurityVulnerabilities();
    
    if (isCritical) {
      // Show critical update dialog
      _showCriticalUpdateDialog(context);
    }
  }
  
  static Future<void> checkForFeatureUpdates(BuildContext context) async {
    // Check if new features are available
    bool hasNewFeatures = await _checkNewFeatures();
    
    if (hasNewFeatures) {
      // Show feature update dialog
      _showFeatureUpdateDialog(context);
    }
  }
}
```

## Platform-Specific Setup

### Android

1. **Add to android/app/build.gradle**:
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

2. **Add to android/app/src/main/AndroidManifest.xml**:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

### iOS

1. **Add to ios/Runner/Info.plist**:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms-apps</string>
</array>
```

## Testing

### 1. Simulate Updates

```dart
// In app_update_config.dart
static const bool simulateUpdateAvailable = true;

// This will always show the update dialog for testing
```

### 2. Test Different Scenarios

- Test on both Android and iOS
- Test with and without internet connection
- Test with different app versions
- Test force update scenarios

## Best Practices

1. **Don't Spam Users**: Use the built-in tracking to show dialogs only once per day
2. **Provide Clear Information**: Explain what's new in the update
3. **Make Updates Easy**: Use in-app updates when possible
4. **Handle Errors Gracefully**: Always provide fallback to store redirect
5. **Test Thoroughly**: Test on real devices with different scenarios

## Troubleshooting

### Common Issues

1. **In-App Update Not Working**:
   - Ensure you're testing on a real device
   - Check that the app is published on Play Store
   - Verify the package name matches

2. **Store Redirect Not Working**:
   - Check app store IDs are correct
   - Ensure app is available on stores
   - Test on real devices

3. **Dialog Not Showing**:
   - Check if dialog was shown today
   - Verify update checking logic
   - Check console for errors

### Debug Mode

Enable debug logging:

```dart
// In app_update_config.dart
static const bool enableLogging = true;
static const bool showDebugInfo = true;
```

## Customization Examples

### 1. Custom Update Dialog

```dart
static void _showCustomUpdateDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => CustomUpdateDialog(
      title: 'New Version Available!',
      message: 'We\'ve added amazing new features!',
      features: [
        'Improved performance',
        'New UI design',
        'Bug fixes',
      ],
      onUpdate: () => _performUpdate(context),
      onLater: () => Navigator.pop(context),
    ),
  );
}
```

### 2. Animated Update Banner

```dart
class AnimatedUpdateBanner extends StatefulWidget {
  @override
  _AnimatedUpdateBannerState createState() => _AnimatedUpdateBannerState();
}

class _AnimatedUpdateBannerState extends State<AnimatedUpdateBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: UpdateBanner(),
    );
  }
}
```

## Support

For issues or questions:
1. Check the console logs for error messages
2. Verify all dependencies are properly installed
3. Test on real devices
4. Check platform-specific requirements

## License

This implementation is provided as-is for educational and development purposes. Feel free to modify and adapt to your needs.
