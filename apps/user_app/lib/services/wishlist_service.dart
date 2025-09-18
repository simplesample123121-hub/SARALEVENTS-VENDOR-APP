import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/simple_cache.dart';
import '../models/service_models.dart';
import 'service_service.dart';

class WishlistService {
  final SupabaseClient _supabase;
  late final ServiceService _serviceService;
  String? _profileTable; // caches detected table name ('profiles' or 'user_profiles')

  WishlistService(this._supabase) {
    _serviceService = ServiceService(_supabase);
  }

  Future<String> _getProfileTable() async {
    if (_profileTable != null) return _profileTable!;
    // Prefer 'profiles', fallback to 'user_profiles'
    for (final candidate in const ['profiles', 'user_profiles']) {
      try {
        await _supabase.from(candidate).select('user_id').limit(1);
        _profileTable = candidate;
        break;
      } catch (_) {
        // try next
      }
    }
    _profileTable ??= 'profiles';
    return _profileTable!;
  }

  /// Get wishlist service IDs for a user
  Future<List<String>> getWishlistIds(String userId) async {
    final key = 'wishlist_ids:$userId';
    return await CacheManager.instance.getOrFetch<List<String>>(
      key,
      const Duration(minutes: 10),
      () async {
        try {
          final table = await _getProfileTable();
          final res = await _supabase
              .from(table)
              .select('wishlist')
              .eq('user_id', userId)
              .maybeSingle();
          
          if (res == null || res['wishlist'] == null) {
            return <String>[];
          }
          
          return List<String>.from(res['wishlist']);
        } catch (e) {
          return <String>[];
        }
      },
    );
  }

  /// Get full wishlist services for a user
  Future<List<ServiceItem>> getWishlistServices(String userId) async {
    final key = 'wishlist_services:$userId';
    return await CacheManager.instance.getOrFetch<List<ServiceItem>>(
      key,
      const Duration(minutes: 5),
      () async {
        final ids = await getWishlistIds(userId);
        if (ids.isEmpty) return <ServiceItem>[];
        
        return await _serviceService.getServicesByIds(ids);
      },
    );
  }

  /// Add service to wishlist
  Future<bool> addToWishlist(String userId, String serviceId) async {
    try {
      final currentIds = await getWishlistIds(userId);
      if (currentIds.contains(serviceId)) {
        return true; // Already in wishlist
      }
      
      final updatedIds = [...currentIds, serviceId];
      await _updateWishlist(userId, updatedIds);
      return true;
    } catch (e) {
      throw Exception('Failed to add to wishlist: ${e.toString()}');
    }
  }

  /// Remove service from wishlist
  Future<bool> removeFromWishlist(String userId, String serviceId) async {
    try {
      final currentIds = await getWishlistIds(userId);
      if (!currentIds.contains(serviceId)) {
        return true; // Already not in wishlist
      }
      
      final updatedIds = currentIds.where((id) => id != serviceId).toList();
      await _updateWishlist(userId, updatedIds);
      return true;
    } catch (e) {
      throw Exception('Failed to remove from wishlist: ${e.toString()}');
    }
  }

  /// Toggle service in wishlist
  Future<bool> toggleWishlist(String userId, String serviceId) async {
    try {
      final currentIds = await getWishlistIds(userId);
      final isInWishlist = currentIds.contains(serviceId);
      
      List<String> updatedIds;
      if (isInWishlist) {
        updatedIds = currentIds.where((id) => id != serviceId).toList();
      } else {
        updatedIds = [...currentIds, serviceId];
      }
      
      await _updateWishlist(userId, updatedIds);
      return !isInWishlist; // Return new state
    } catch (e) {
      throw Exception('Failed to toggle wishlist: ${e.toString()}');
    }
  }

  /// Check if service is in wishlist
  Future<bool> isInWishlist(String userId, String serviceId) async {
    try {
      final ids = await getWishlistIds(userId);
      return ids.contains(serviceId);
    } catch (e) {
      return false;
    }
  }

  /// Clear entire wishlist
  Future<void> clearWishlist(String userId) async {
    try {
      await _updateWishlist(userId, <String>[]);
    } catch (e) {
      throw Exception('Failed to clear wishlist: ${e.toString()}');
    }
  }

  /// Get wishlist count
  Future<int> getWishlistCount(String userId) async {
    try {
      final ids = await getWishlistIds(userId);
      return ids.length;
    } catch (e) {
      return 0;
    }
  }

  /// Private method to update wishlist in database
  Future<void> _updateWishlist(String userId, List<String> serviceIds) async {
    try {
      // Ensure profile exists
      await _ensureProfileExists(userId);
      
      // Update wishlist
      final table = await _getProfileTable();
      await _supabase
          .from(table)
          .update({
            'wishlist': serviceIds,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Invalidate caches
      _invalidateCaches(userId);
    } catch (e) {
      throw Exception('Database update failed: ${e.toString()}');
    }
  }

  /// Ensure user profile exists
  Future<void> _ensureProfileExists(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final table = await _getProfileTable();
      
      final existing = await _supabase
          .from(table)
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing == null) {
        await _supabase
            .from(table)
            .insert({
              'user_id': userId,
              'email': user.email ?? '',
              'first_name': '',
              'last_name': '',
              'wishlist': <String>[],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('duplicate key')) {
        rethrow;
      }
    }
  }

  /// Invalidate related caches
  void _invalidateCaches(String userId) {
    CacheManager.instance.invalidate('wishlist_ids:$userId');
    CacheManager.instance.invalidate('wishlist_services:$userId');
    CacheManager.instance.invalidate('profile:$userId');
  }
}