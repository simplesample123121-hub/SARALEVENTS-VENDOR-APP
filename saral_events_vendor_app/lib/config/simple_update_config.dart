class SimpleUpdateConfig {
  // App Store URLs - Replace with your actual URLs
  static const String androidPackageName = 'com.example.saral_events_vendor_app';
  static const String iOSAppId = 'your_ios_app_id';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.saral_events_vendor_app';
  static const String appStoreUrl = 'https://apps.apple.com/app/id123456789';
  
  // Update Check Settings
  static const bool checkOnAppStart = true;
  static const bool checkOnAppResume = false;
  static const Duration startupDelay = Duration(seconds: 2);
  static const Duration checkInterval = Duration(days: 1);
  
  // Dialog Settings
  static const bool forceUpdate = false; // If true, user cannot dismiss dialog
  static const bool showSkipButton = true;
  static const String dialogTitle = 'Update Available';
  static const String dialogMessage = 'A new version of Saral Events Vendor App is available!';
  static const String dialogSubMessage = 'Update now to get the latest features and improvements.';
  static const String updateButtonText = 'Update Now';
  static const String skipButtonText = 'Later';
  
  // Banner Settings
  static const bool showBanner = true;
  static const String bannerTitle = 'Update Available';
  static const String bannerSubtitle = 'Get the latest features and improvements';
  
  // Colors
  static const int primaryColor = 0xFF2196F3; // Blue
  static const int accentColor = 0xFF1976D2; // Darker Blue
  static const int textColor = 0xFFFFFFFF; // White
  static const int secondaryTextColor = 0xB3FFFFFF; // White with opacity
  
  // Customization
  static const bool showUpdateIcon = true;
  static const bool showProgressIndicator = true;
  static const bool enableSound = false;
  static const bool enableVibration = false;
  
  // Feature Flags
  static const bool enableUpdateNotifications = true;
  static const bool showWhatsNewSection = true;
  
  // Debug Settings
  static const bool enableLogging = true;
  static const bool showDebugInfo = false;
  static const bool simulateUpdateAvailable = true; // For testing - set to false in production
  
  // What's New Content
  static const List<String> whatsNewFeatures = [
    'Improved performance and stability',
    'New user interface design',
    'Bug fixes and security updates',
    'Enhanced event management features',
    'Better user experience',
    'New notification system',
  ];
  
  // Update Priority
  static const UpdatePriority updatePriority = UpdatePriority.normal;
  
  // Minimum Required Version (for force updates)
  static const String minimumRequiredVersion = '1.0.0';
}

enum UpdatePriority {
  low,
  normal,
  high,
  critical,
}
