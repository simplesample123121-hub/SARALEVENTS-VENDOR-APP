class AddressUtils {
  /// Extracts area name from a full address string
  /// Returns the most relevant area identifier (locality, subLocality, or administrativeArea)
  static String extractAreaName(String fullAddress) {
    if (fullAddress.isEmpty) return 'Select location';
    
    // Split address by common separators
    final parts = fullAddress.split(',').map((e) => e.trim()).toList();
    
    if (parts.isEmpty) return 'Select location';
    
    // Try to find the most relevant area name
    // Priority: locality > subLocality > administrativeArea > first part
    
    // Look for common area indicators
    for (final part in parts) {
      if (part.toLowerCase().contains('area') || 
          part.toLowerCase().contains('colony') ||
          part.toLowerCase().contains('nagar') ||
          part.toLowerCase().contains('pura') ||
          part.toLowerCase().contains('vihar') ||
          part.toLowerCase().contains('enclave') ||
          part.toLowerCase().contains('sector') ||
          part.toLowerCase().contains('phase')) {
        return part;
      }
    }
    
    // If no specific area found, try to get the second part (usually locality)
    if (parts.length >= 2) {
      return parts[1];
    }
    
    // Fallback to first part if it's not too long
    if (parts[0].length <= 20) {
      return parts[0];
    }
    
    // If first part is too long, truncate it
    return parts[0].length > 20 ? '${parts[0].substring(0, 17)}...' : parts[0];
  }
  
  /// Formats address for display with proper truncation
  static String formatAddressForDisplay(String address, {int maxLength = 50}) {
    if (address.length <= maxLength) return address;
    return '${address.substring(0, maxLength - 3)}...';
  }
}
