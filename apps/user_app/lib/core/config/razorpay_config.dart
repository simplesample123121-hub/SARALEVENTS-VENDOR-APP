/// Razorpay configuration constants
/// 
/// IMPORTANT SECURITY NOTES:
/// - These are LIVE production keys - handle with extreme care
/// - In a real production app, these should be stored securely on the server
/// - Never commit these keys to version control in production
/// - Consider using environment variables or secure vaults
class RazorpayConfig {
  // Live production keys - provided by client
  static const String keyId = 'rzp_live_RNhz4a9K9h6SNQ';
  static const String keySecret = 'YO1h1gkF3upgD2fClwPVrfjG';
  
  // App configuration
  static const String appName = 'Saral Events';
  static const String currency = 'INR';
  static const String themeColor = '#FDBB42';
  
  // Payment configuration
  static const bool autoCapture = true;
  static const int timeout = 300; // 5 minutes
  
  // Validation
  static bool get isConfigured => keyId.isNotEmpty && keySecret.isNotEmpty;
  
  /// Validates the configuration
  static void validate() {
    if (!isConfigured) {
      throw Exception('Razorpay configuration is incomplete');
    }
    
    if (!keyId.startsWith('rzp_')) {
      throw Exception('Invalid Razorpay Key ID format');
    }
  }
}
