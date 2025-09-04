# Simple App Update Notification System for Flutter

A lightweight, easy-to-implement solution for notifying users about app updates in your Flutter application. This version uses only basic Flutter packages and doesn't require complex external dependencies.

## Features

- ✅ **Store Redirects** - Redirects users to Play Store/App Store
- ✅ **Custom Update Dialogs** - Beautiful, branded update notifications
- ✅ **Smart Update Checking** - Prevents spam by tracking when dialogs were shown
- ✅ **Multiple Integration Options** - Easy to add to any screen
- ✅ **Configurable** - Easy to customize appearance and behavior
- ✅ **Platform Aware** - Different strategies for Android and iOS
- ✅ **Lightweight** - Uses only basic Flutter packages

## Installation

The required dependencies are already included in your `pubspec.yaml`:

```yaml
dependencies:
  package_info_plus: ^8.0.2
  shared_preferences: ^2.3.2
  url_launcher: ^6.3.0
```

## Quick Start

### Option 1: Automatic Integration (Recommended)

Wrap your `MaterialApp` with `SimpleUpdateWidget`:

```dart
import 'package:your_app/widgets/simple_update_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleUpdateWidget(
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
import 'package:your_app/services/simple_app_update_service.dart';

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
      SimpleAppUpdateService.checkOnStartup(context);
    });
  }
  
  // Manual update check
  void _checkForUpdates() {
    SimpleAppUpdateService.forceCheckForUpdates(context);
  }
}
```

## Configuration

### 1. Update App Store URLs

Edit `lib/config/simple_update_config.dart`:

```dart
class SimpleUpdateConfig {
  // Replace with your actual app URLs
  static const String androidPackageName = 'com.yourcompany.yourapp';
  static const String iOSAppId = 'your_ios_app_id';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.yourcompany.yourapp';
  static const String appStoreUrl = 'https://apps.apple.com/app/id123456789';
  
  // Customize behavior
  static const bool checkOnAppStart = true;
  static const bool forceUpdate = false;
  static const Duration startupDelay = Duration(seconds: 2);
}
```

### 2. Customize Update Dialog

```dart
// In simple_update_config.dart
static const String dialogTitle = 'Update Available';
static const String dialogMessage = 'A new version is available!';
static const String updateButtonText = 'Update Now';
static const String skipButtonText = 'Later';
```

### 3. Customize What's New Section

```dart
// In simple_update_config.dart
static const List<String> whatsNewFeatures = [
  'Improved performance and stability',
  'New user interface design',
  'Bug fixes and security updates',
  'Enhanced event management features',
];
```

## Integration Options

### 1. Update Banner

Show a banner at the top of any screen:

```dart
import 'package:your_app/widgets/simple_update_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SimpleUpdateBanner(
          onUpdatePressed: () {
            SimpleAppUpdateService.forceCheckForUpdates(context);
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
import 'package:your_app/widgets/simple_update_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YourContent(),
      floatingActionButton: SimpleUpdateFloatingActionButton(
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
        SimpleAppUpdateService.forceCheckForUpdates(context);
      },
      tooltip: 'Check for Updates',
    ),
  ],
)
```

### 4. Settings Tile

Add update information to settings:

```dart
import 'package:your_app/widgets/simple_update_widget.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        UpdateInfoTile(
          onCheckForUpdates: () {
            SimpleAppUpdateService.forceCheckForUpdates(context);
          },
        ),
        // Other settings tiles
      ],
    );
  }
}
```

## Advanced Features

### 1. Backend Version Checking

Implement your own version checking logic:

```dart
// In simple_app_update_service.dart, modify _isUpdateAvailable method
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
// In simple_update_config.dart
static const bool forceUpdate = true;

// In simple_app_update_service.dart, modify dialog
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
              onPressed: () => _performUpdate(),
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

1. **Add to android/app/src/main/AndroidManifest.xml**:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

2. **Update your package name** in the configuration file to match your actual package name.

### iOS

1. **Add to ios/Runner/Info.plist**:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms-apps</string>
</array>
```

2. **Update your iOS app ID** in the configuration file.

## Testing

### 1. Simulate Updates

```dart
// In simple_update_config.dart
static const bool simulateUpdateAvailable = true;

// This will always show the update dialog for testing
// Set to false in production
```

### 2. Test Different Scenarios

- Test on both Android and iOS
- Test with and without internet connection
- Test with different app versions
- Test force update scenarios

### 3. Reset Update Tracking

```dart
// Useful for testing
await SimpleAppUpdateService.resetUpdateTracking();
```

## Best Practices

1. **Don't Spam Users**: The system automatically tracks when dialogs were shown
2. **Provide Clear Information**: Use the "What's New" section to explain updates
3. **Make Updates Easy**: Provide clear store redirects
4. **Handle Errors Gracefully**: Always provide fallback options
5. **Test Thoroughly**: Test on real devices with different scenarios

## Troubleshooting

### Common Issues

1. **Store Redirect Not Working**:
   - Check app store URLs are correct
   - Ensure app is available on stores
   - Test on real devices

2. **Dialog Not Showing**:
   - Check if dialog was shown today
   - Verify update checking logic
   - Check console for errors

3. **Configuration Not Working**:
   - Ensure configuration file is properly imported
   - Check that constants are properly set

### Debug Mode

Enable debug logging:

```dart
// In simple_update_config.dart
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
      onUpdate: () => _performUpdate(),
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
      child: SimpleUpdateBanner(),
    );
  }
}
```

### 3. Custom Update Service

```dart
class CustomUpdateService extends SimpleAppUpdateService {
  static Future<void> checkForBetaUpdates(BuildContext context) async {
    // Check if user is in beta program
    bool isBetaUser = await _checkBetaStatus();
    
    if (isBetaUser) {
      // Show beta update dialog
      _showBetaUpdateDialog(context);
    }
  }
  
  static Future<void> checkForSecurityUpdates(BuildContext context) async {
    // Check for security vulnerabilities
    bool hasSecurityIssues = await _checkSecurityVulnerabilities();
    
    if (hasSecurityIssues) {
      // Show security update dialog
      _showSecurityUpdateDialog(context);
    }
  }
}
```

## Migration from Complex Version

If you were using the complex version with `in_app_update`, you can easily migrate:

1. **Replace imports**:
```dart
// Old
import 'package:your_app/services/app_update_service.dart';
import 'package:your_app/widgets/app_update_widget.dart';

// New
import 'package:your_app/services/simple_app_update_service.dart';
import 'package:your_app/widgets/simple_update_widget.dart';
```

2. **Update service calls**:
```dart
// Old
AppUpdateService.checkForUpdates(context);

// New
SimpleAppUpdateService.checkForUpdates(context);
```

3. **Update widget usage**:
```dart
// Old
AppUpdateWidget(child: YourApp())

// New
SimpleUpdateWidget(child: YourApp())
```

## Support

For issues or questions:
1. Check the console logs for error messages
2. Verify all dependencies are properly installed
3. Test on real devices
4. Check platform-specific requirements

## License

This implementation is provided as-is for educational and development purposes. Feel free to modify and adapt to your needs.

## What's Next?

Once you have the basic update system working, you can enhance it with:

1. **Backend Integration**: Connect to your server for version checking
2. **Analytics**: Track update acceptance rates
3. **A/B Testing**: Test different update messages
4. **Localization**: Support multiple languages
5. **Custom Themes**: Match your app's design system
