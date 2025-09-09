import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation_models.dart';

class InvitationService {
  final SupabaseClient _supabase;
  InvitationService(this._supabase);

  Future<List<InvitationItem>> listMyInvitations() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return <InvitationItem>[];
    final rows = await _supabase
        .from('invitations')
        .select('*')
        .eq('user_id', uid)
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => InvitationItem.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<InvitationItem?> getBySlug(String slug) async {
    final row = await _supabase
        .from('invitations')
        .select('*')
        .eq('slug', slug)
        .maybeSingle();
    if (row == null) return null;
    return InvitationItem.fromMap(Map<String, dynamic>.from(row));
  }

  String generateSlug(String title) {
    final sanitized = title.trim().toLowerCase();
    final step1 = sanitized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final step2 = step1.replaceAll(RegExp('-+'), '-');
    final base = step2.replaceAll(RegExp(r'^-+|-+$'), '');
    final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(9); // short suffix
    return '$base-$ts';
  }

  Future<String?> uploadCoverImage(String localPath) async {
    if (localPath.startsWith('http')) return localPath;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final file = File(localPath);
    if (!await file.exists()) return null;
    final name = localPath.split('/').isNotEmpty ? localPath.split('/').last : 'cover.jpg';
    final objectPath = 'invitations/$uid/${DateTime.now().millisecondsSinceEpoch}_$name';
    await _supabase.storage.from('user-app-assets').upload(objectPath, file);
    return _supabase.storage.from('user-app-assets').getPublicUrl(objectPath);
  }

  Future<List<String>> uploadGallery(List<String> paths) async {
    final result = <String>[];
    for (final p in paths) {
      final url = await uploadCoverImage(p);
      if (url != null) result.add(url);
    }
    return result;
  }

  Future<InvitationItem?> createInvitation({
    required String title,
    String? description,
    DateTime? eventDate,
    String? eventTime,
    String? venueName,
    String? address,
    String? coverImagePath,
    List<String> galleryLocalPaths = const <String>[],
    InvitationVisibility visibility = InvitationVisibility.unlisted,
    int? rsvpLimit,
    String? theme,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final slug = generateSlug(title);
    final coverUrl = coverImagePath != null ? await uploadCoverImage(coverImagePath) : null;
    final galleryUrls = await uploadGallery(galleryLocalPaths);
    final inserted = await _supabase
        .from('invitations')
        .insert({
          'user_id': uid,
          'title': title,
          'description': description,
          'event_date': eventDate?.toIso8601String(),
          'event_time': eventTime,
          'venue_name': venueName,
          'address': address,
          'cover_image_url': coverUrl,
          'gallery_urls': galleryUrls,
          'slug': slug,
          'visibility': visibility.name,
          'rsvp_limit': rsvpLimit,
          'theme': theme,
        })
        .select()
        .single();
    return InvitationItem.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<InvitationItem?> updateInvitation(String id, Map<String, dynamic> updates) async {
    final updated = await _supabase
        .from('invitations')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return InvitationItem.fromMap(Map<String, dynamic>.from(updated));
  }

  Future<bool> deleteInvitation(String id) async {
    await _supabase.from('invitations').delete().eq('id', id);
    return true;
  }

  Future<bool> createRsvp({
    required String invitationId,
    String? name,
    String? email,
    String? phone,
    String status = 'yes',
    int? guestsCount,
    String? note,
  }) async {
    await _supabase.from('invitation_rsvps').insert({
      'invitation_id': invitationId,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'guests_count': guestsCount,
      'note': note,
    });
    return true;
  }
}


