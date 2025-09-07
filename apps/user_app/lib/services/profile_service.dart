import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/simple_cache.dart';

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
  }) async {
    final data = {
      'user_id': userId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
    };
    await _supabase.from('user_profiles').upsert(data);
    CacheManager.instance.invalidate('profile:$userId');
    return true;
  }
}
