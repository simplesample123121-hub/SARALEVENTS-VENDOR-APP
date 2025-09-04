import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_models.dart';

class ServiceService {
  final SupabaseClient _supabase;

  ServiceService(this._supabase);

  // Fetch all active services from all vendors
  Future<List<ServiceItem>> getAllServices() async {
    try {
      final result = await _supabase
          .from('services')
          .select('''
            *,
            vendor_profiles!inner(
              id,
              business_name,
              address,
              category
            )
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return result.map((row) {
        final vendorProfile = row['vendor_profiles'];
        final vendorId = vendorProfile['id'] ?? '';
        final vendorName = vendorProfile['business_name'] ?? 'Unknown Vendor';
        
        print('Service: ${row['name']}');
        print('  Service ID: ${row['id']}');
        print('  Vendor Profile: $vendorProfile');
        print('  Vendor ID: $vendorId');
        print('  Vendor Name: $vendorName');
        
        return ServiceItem(
          id: row['id'],
          categoryId: row['category_id'],
          name: row['name'],
          price: (row['price'] ?? 0).toDouble(),
          tags: List<String>.from(row['tags'] ?? []),
          description: row['description'] ?? '',
          media: (row['media_urls'] as List<dynamic>?)
                  ?.map((url) => MediaItem(url: url, type: MediaType.image))
                  .toList() ??
              [],
          enabled: row['is_active'] ?? true,
          vendorId: vendorId,
          vendorName: vendorName,
        );
      }).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Fetch all categories from all vendors
  Future<List<CategoryNode>> getAllCategories() async {
    try {
      final result = await _supabase
          .from('categories')
          .select('*')
          .order('name');

      return result.map((row) => CategoryNode(
        id: row['id'],
        name: row['name'],
        subcategories: [], // Will be populated separately if needed
        services: [], // Will be populated separately if needed
      )).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Fetch services by category
  Future<List<ServiceItem>> getServicesByCategory(String categoryId) async {
    try {
      final result = await _supabase
          .from('services')
          .select('''
            *,
            vendor_profiles!inner(
              id,
              business_name,
              address,
              category
            )
          ''')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return result.map((row) {
        final vendorProfile = row['vendor_profiles'];
        return ServiceItem(
          id: row['id'],
          categoryId: row['category_id'],
          name: row['name'],
          price: (row['price'] ?? 0).toDouble(),
          tags: List<String>.from(row['tags'] ?? []),
          description: row['description'] ?? '',
          media: (row['media_urls'] as List<dynamic>?)
                  ?.map((url) => MediaItem(url: url, type: MediaType.image))
                  .toList() ??
              [],
          enabled: row['is_active'] ?? true,
          vendorId: vendorProfile['id'] ?? '',
          vendorName: vendorProfile['business_name'] ?? 'Unknown Vendor',
        );
      }).toList();
    } catch (e) {
      print('Error fetching services by category: $e');
      return [];
    }
  }

  // Search services by query
  Future<List<ServiceItem>> searchServices(String query) async {
    try {
      final result = await _supabase
          .from('services')
          .select('''
            *,
            vendor_profiles!inner(
              id,
              business_name,
              address,
              category
            )
          ''')
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return result.map((row) {
        final vendorProfile = row['vendor_profiles'];
        return ServiceItem(
          id: row['id'],
          categoryId: row['category_id'],
          name: row['name'],
          price: (row['price'] ?? 0).toDouble(),
          tags: List<String>.from(row['tags'] ?? []),
          description: row['description'] ?? '',
          media: (row['media_urls'] as List<dynamic>?)
                  ?.map((url) => MediaItem(url: url, type: MediaType.image))
                  .toList() ??
              [],
          enabled: row['is_active'] ?? true,
          vendorId: vendorProfile['id'] ?? '',
          vendorName: vendorProfile['business_name'] ?? 'Unknown Vendor',
        );
      }).toList();
    } catch (e) {
      print('Error searching services: $e');
      return [];
    }
  }
}
