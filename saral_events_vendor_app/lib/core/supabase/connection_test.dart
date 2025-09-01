import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConnectionTest {
  static Future<void> testConnection() async {
    try {
      final supabase = Supabase.instance.client;
      
      print('🔍 Testing Supabase connection...');
      
      // Test basic connection
      final response = await supabase.from('vendor_profiles').select('count').limit(1);
      print('✅ Database connection successful!');
      
      // Test storage bucket
      try {
        final buckets = await supabase.storage.listBuckets();
        final vendorBucket = buckets.where((bucket) => bucket.id == 'vendor_documents').firstOrNull;
        if (vendorBucket != null) {
          print('✅ Storage bucket "vendor_documents" exists!');
        } else {
          print('❌ Storage bucket "vendor_documents" not found');
        }
      } catch (e) {
        print('❌ Storage test failed: $e');
      }
      
    } catch (e) {
      print('❌ Connection test failed: $e');
      print('Make sure you have run the SQL schema in your Supabase dashboard');
    }
  }
  
  static Future<void> testVendorProfileCreation() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Test creating a vendor profile
      final testProfile = {
        'user_id': 'test-user-123',
        'business_name': 'Test Business',
        'address': 'Test Address',
        'category': 'Test Category',
        'services': ['Service 1', 'Service 2'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final result = await supabase
          .from('vendor_profiles')
          .insert(testProfile)
          .select()
          .single();
      
      print('✅ Test vendor profile created successfully!');
      print('Profile ID: ${result['id']}');
      
      // Clean up test data
      await supabase
          .from('vendor_profiles')
          .delete()
          .eq('user_id', 'test-user-123');
      
      print('✅ Test data cleaned up');
      
    } catch (e) {
      print('❌ Vendor profile test failed: $e');
    }
  }
}
