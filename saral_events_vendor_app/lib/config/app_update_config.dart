class AppUpdateConfig {
  // App Store IDs - Replace with your actual IDs
  static const String androidPackageName = 'com.example.saral_events_vendor_app';
  static const String iOSAppId = 'your_ios_app_id';
  
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
  static const bool showBanner = false;
  static const String bannerTitle = 'Update Available';
  static const String bannerSubtitle = 'Get the latest features and improvements';
  
  // Colors
  static const int primaryColor = 0xFF2196F3; // Blue
  static const int accentColor = 0xFF1976D2; // Darker Blue
  static const int textColor = 0xFFFFFFFF; // White
  static const int secondaryTextColor = 0xB3FFFFFF; // White with opacity
  
  // API Configuration
  static const String versionCheckUrl = 'https://your-backend.com/api/latest-version';
  static const Duration apiTimeout = Duration(seconds: 10);
  
  // In-App Update Settings (Android)
  static const bool enableInAppUpdate = true;
  static const bool preferImmediateUpdate = true;
  static const bool fallbackToStore = true;
  
  // Customization
  static const bool showUpdateIcon = true;
  static const bool showProgressIndicator = true;
  static const bool enableSound = false;
  static const bool enableVibration = false;
  
  // Localization
  static const Map<String, String> messages = {
    'en': 'Update Available',
    'hi': 'अपडेट उपलब्ध है',
    'es': 'Actualización Disponible',
    'fr': 'Mise à jour Disponible',
  };
  
  // Feature Flags
  static const bool enableBetaUpdates = false;
  static const bool enableAutoDownload = false;
  static const bool enableUpdateNotifications = true;
  
  // Debug Settings
  static const bool enableLogging = true;
  static const bool showDebugInfo = false;
  static const bool simulateUpdateAvailable = false; // For testing
}
