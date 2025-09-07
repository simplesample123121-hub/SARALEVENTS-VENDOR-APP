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
            .from('user_profiles')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();
        return res as Map<String, dynamic>?;
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
    await _supabase
        .from('user_profiles')
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
}
