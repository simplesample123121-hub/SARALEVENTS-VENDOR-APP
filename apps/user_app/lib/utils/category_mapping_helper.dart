import 'package:flutter/foundation.dart';
import '../models/event_models.dart';

class CategoryMappingHelper {
  /// Maps display category names to database category names
  static const Map<String, String> categoryMapping = {
    // Event category display names to database names
    'Venues': 'Venue',
    'Decors': 'Decoration',
    'Catering': 'Catering',
    'Photography': 'Photography',
    'Makeup Artist': 'Essentials',
    'Music & Dance': 'Music/Dj',
    'Entertainment': 'Music/Dj',
    'AV Equipment': 'Essentials',
    'Decoration': 'Decoration',
    
    // Direct mappings (display name = database name)
    'Venue': 'Venue',
    'Music/Dj': 'Music/Dj',
    'Essentials': 'Essentials',
    'Farmhouse': 'Farmhouse',
  };

  /// Available database categories (from home screen categories)
  static const List<String> availableCategories = [
    'Photography',
    'Decoration', 
    'Catering',
    'Venue',
    'Farmhouse',
    'Music/Dj',
    'Essentials',
  ];

  /// Get database category name from display name
  static String getDatabaseCategory(String displayName) {
    return categoryMapping[displayName] ?? displayName;
  }

  /// Check if a category exists in the database
  static bool isValidCategory(String categoryName) {
    return availableCategories.contains(categoryName);
  }

  /// Get all event categories for debugging
  static void debugEventCategories() {
    debugPrint('=== Event Categories Debug ===');
    for (final eventType in EventData.eventTypes) {
      debugPrint('Event: ${eventType.name} (${eventType.id})');
      final categories = EventData.getCategoriesForEvent(eventType.id);
      for (final category in categories) {
        final dbCategory = category.databaseCategory;
        final isValid = isValidCategory(dbCategory);
        debugPrint('  - ${category.name} → $dbCategory ${isValid ? '✓' : '✗'}');
      }
      debugPrint('');
    }
    debugPrint('Available DB Categories: ${availableCategories.join(', ')}');
    debugPrint('=== End Debug ===');
  }
}