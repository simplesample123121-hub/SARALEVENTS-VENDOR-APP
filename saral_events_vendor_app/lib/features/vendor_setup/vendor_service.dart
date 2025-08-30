import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_models.dart';

class VendorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create or update vendor profile
  Future<VendorProfile> saveVendorProfile(VendorProfile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if vendor profile already exists
      final existingProfile = await _supabase
          .from('vendor_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      if (existingProfile != null) {
        // Update existing profile
        final updatedData = {
          ...profile.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        final result = await _supabase
            .from('vendor_profiles')
            .update(updatedData)
            .eq('user_id', userId)
            .select()
            .single();
            
        return VendorProfile.fromJson(result);
      } else {
        // Create new profile
        final newData = {
          ...profile.toJson(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        final result = await _supabase
            .from('vendor_profiles')
            .insert(newData)
            .select()
            .single();
            
        return VendorProfile.fromJson(result);
      }
    } catch (e) {
      throw Exception('Failed to save vendor profile: $e');
    }
  }

  // Get vendor profile by user ID
  Future<VendorProfile?> getVendorProfile(String userId) async {
    try {
      final result = await _supabase
          .from('vendor_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (result == null) return null;
      return VendorProfile.fromJson(result);
    } catch (e) {
      throw Exception('Failed to get vendor profile: $e');
    }
  }

  // Upload document file to Supabase storage
  Future<String> uploadDocument(File file, String documentType, String vendorId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'vendor_documents/$vendorId/$documentType/$fileName';
      
      // Upload file to storage
      await _supabase.storage
          .from('vendor_documents')
          .upload(filePath, file);

      // Get public URL
      final fileUrl = _supabase.storage
          .from('vendor_documents')
          .getPublicUrl(filePath);

      // Save document record to database
      final document = VendorDocument(
        vendorId: vendorId,
        documentType: documentType,
        fileName: fileName,
        filePath: filePath,
        fileUrl: fileUrl,
        uploadedAt: DateTime.now(),
      );

      await _supabase
          .from('vendor_documents')
          .insert(document.toJson());

      return fileUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Get vendor documents
  Future<List<VendorDocument>> getVendorDocuments(String vendorId) async {
    try {
      final result = await _supabase
          .from('vendor_documents')
          .select()
          .eq('vendor_id', vendorId)
          .order('uploaded_at', ascending: false);

      return result.map((doc) => VendorDocument.fromJson(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get vendor documents: $e');
    }
  }

  // Delete vendor document
  Future<void> deleteDocument(String documentId, String filePath) async {
    try {
      // Delete from storage
      await _supabase.storage
          .from('vendor_documents')
          .remove([filePath]);

      // Delete from database
      await _supabase
          .from('vendor_documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Check if vendor profile exists
  Future<bool> hasVendorProfile(String userId) async {
    try {
      final result = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      return false;
    }
  }
}
