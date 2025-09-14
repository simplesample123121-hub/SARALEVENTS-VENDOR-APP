import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/simple_cache.dart';
import 'dart:io';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final key = 'profile:$userId';
    return await CacheManager.instance.getOrFetch<Map<String, dynamic>?>(
      key,
      const Duration(minutes: 5),
      () async {
        final res = await _supabase
            .from('profiles')
            .select('*')
            .eq('id', userId)
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
      'id': userId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      if (imageUrl != null) 'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase
        .from('profiles')
        .upsert(data, onConflict: 'id');
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
    final res = await _supabase
        .from('profiles')
        .select('wishlist')
        .eq('id', userId)
        .maybeSingle();
    final wish = (res != null && res['wishlist'] is List)
        ? List<String>.from(res['wishlist'].map((e) => e.toString()))
        : <String>[];
    return wish;
  }

  Future<List<String>> toggleWishlist({
    required String userId,
    required String serviceId,
  }) async {
    // Fetch current wishlist
    final current = await getWishlistServiceIds(userId);
    final exists = current.contains(serviceId);
    final updated = List<String>.from(current);
    if (exists) {
      updated.remove(serviceId);
    } else {
      updated.add(serviceId);
    }

    // Update in DB
    await _supabase
        .from('profiles')
        .update({'wishlist': updated})
        .eq('id', userId);

    // Invalidate cached profile
    CacheManager.instance.invalidate('profile:$userId');
    return updated;
  }
}
