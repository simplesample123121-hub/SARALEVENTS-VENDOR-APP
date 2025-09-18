import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/simple_cache.dart';
import 'dart:io';

class ProfileService {
  final SupabaseClient _supabase;
  String? _profileTable;

  ProfileService(this._supabase);

  Future<String> _getProfileTable() async {
    if (_profileTable != null) return _profileTable!;
    for (final candidate in const ['profiles', 'user_profiles']) {
      try {
        await _supabase.from(candidate).select('user_id').limit(1);
        _profileTable = candidate;
        break;
      } catch (_) {}
    }
    _profileTable ??= 'profiles';
    return _profileTable!;
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final key = 'profile:$userId';
    return await CacheManager.instance.getOrFetch<Map<String, dynamic>?>(
      key,
      const Duration(minutes: 5),
      () async {
        final table = await _getProfileTable();
        final res = await _supabase
            .from(table)
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();
        return res;
      },
    );
  }

  Future<bool> upsertProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    final data = {
      'user_id': userId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      if (imageUrl != null) 'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final table = await _getProfileTable();
    await _supabase
        .from(table)
        .upsert(data, onConflict: 'user_id');
    CacheManager.instance.invalidate('profile:$userId');
    return true;
  }

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
    required String fileName,
  }) async {
    final path = 'avatars/$userId/$fileName';
    final storage = _supabase.storage.from('user-avatars');
    await storage.upload(path, file, fileOptions: const FileOptions(upsert: true));
    final publicUrl = storage.getPublicUrl(path);
    return publicUrl;
  }

  // Wishlist APIs
  Future<List<String>> getWishlistServiceIds(String userId) async {
    final key = 'wishlist:$userId';
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
          
          final wishlist = (res != null && res['wishlist'] is List)
              ? List<String>.from(res['wishlist'].map((e) => e.toString()))
              : <String>[];
          
          return wishlist;
        } catch (e) {
          // If profile doesn't exist, create it
          if (e.toString().contains('PGRST116')) {
            await _createEmptyProfile(userId);
            return <String>[];
          }
          rethrow;
        }
      },
    );
  }

  Future<List<String>> toggleWishlist({
    required String userId,
    required String serviceId,
  }) async {
    try {
      // Fetch current wishlist
      final current = await getWishlistServiceIds(userId);
      final exists = current.contains(serviceId);
      final updated = List<String>.from(current);
      
      if (exists) {
        updated.remove(serviceId);
      } else {
        updated.add(serviceId);
      }

      // Update in DB with upsert to handle missing profiles
      final table = await _getProfileTable();
      await _supabase
          .from(table)
          .upsert({
            'user_id': userId,
            'wishlist': updated,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');

      // Invalidate caches
      CacheManager.instance.invalidate('profile:$userId');
      CacheManager.instance.invalidate('wishlist:$userId');
      
      return updated;
    } catch (e) {
      throw Exception('Failed to update wishlist: ${e.toString()}');
    }
  }

  Future<void> _createEmptyProfile(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final table = await _getProfileTable();
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
    } catch (e) {
      // Ignore if profile already exists
      if (!e.toString().contains('duplicate key')) {
        rethrow;
      }
    }
  }
}
