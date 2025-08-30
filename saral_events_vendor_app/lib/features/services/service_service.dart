import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_models.dart';

class ServiceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get vendor ID for current user
  Future<String?> _getVendorId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final result = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return result?['id'];
    } catch (e) {
      print('Error getting vendor ID: $e');
      return null;
    }
  }

  // Get all categories for current vendor
  Future<List<CategoryNode>> getCategories() async {
    try {
      final vendorId = await _getVendorId();
      if (vendorId == null) return [];

      final result = await _supabase
          .from('categories')
          .select()
          .eq('vendor_id', vendorId)
          .order('name');

      // Convert to CategoryNode structure
      final categories = <CategoryNode>[];
      final categoryMap = <String, CategoryNode>{};

      // First pass: create all category nodes
      for (final row in result) {
        final category = CategoryNode(
          id: row['id'],
          name: row['name'],
          subcategories: [],
          services: [],
        );
        categoryMap[row['id']] = category;
      }

      // Second pass: build hierarchy
      for (final row in result) {
        final category = categoryMap[row['id']]!;
        if (row['parent_id'] == null) {
          categories.add(category);
        } else {
          final parent = categoryMap[row['parent_id']];
          if (parent != null) {
            parent!.subcategories.add(category);
          }
        }
      }

      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Create new category
  Future<CategoryNode?> createCategory(String name, String? parentId) async {
    try {
      final vendorId = await _getVendorId();
      if (vendorId == null) return null;

      final result = await _supabase
          .from('categories')
          .insert({
            'vendor_id': vendorId,
            'name': name,
            'parent_id': parentId,
          })
          .select()
          .single();

      return CategoryNode(
        id: result['id'],
        name: result['name'],
        subcategories: [],
        services: [],
      );
    } catch (e) {
      print('Error creating category: $e');
      return null;
    }
  }

  // Update category
  Future<bool> updateCategory(String categoryId, String name) async {
    try {
      await _supabase
          .from('categories')
          .update({'name': name})
          .eq('id', categoryId);

      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      // Check if category has services or subcategories
      final hasServices = await _supabase
          .from('services')
          .select('id')
          .eq('category_id', categoryId)
          .limit(1)
          .maybeSingle();

      final hasSubcategories = await _supabase
          .from('categories')
          .select('id')
          .eq('parent_id', categoryId)
          .limit(1)
          .maybeSingle();

      if (hasServices != null || hasSubcategories != null) {
        throw Exception('Cannot delete category with services or subcategories');
      }

      await _supabase
          .from('categories')
          .delete()
          .eq('id', categoryId);

      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // Get services for a category
  Future<List<ServiceItem>> getServices(String categoryId) async {
    try {
      final result = await _supabase
          .from('services')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return result.map((row) => ServiceItem(
        id: row['id'],
        name: row['name'],
        price: row['price']?.toDouble() ?? 0.0,
        tags: List<String>.from(row['tags'] ?? []),
        description: row['description'] ?? '',
        media: (row['media_urls'] as List<dynamic>?)
                ?.map((url) => MediaItem(url: url, type: MediaType.image))
                .toList() ?? [],
      )).toList();
    } catch (e) {
      print('Error getting services: $e');
      return [];
    }
  }

  // Create new service
  Future<ServiceItem?> createService({
    required String name,
    required String categoryId,
    required double price,
    required List<String> tags,
    required String description,
    required List<String> mediaUrls,
  }) async {
    try {
      final vendorId = await _getVendorId();
      if (vendorId == null) return null;

      final result = await _supabase
          .from('services')
          .insert({
            'vendor_id': vendorId,
            'category_id': categoryId,
            'name': name,
            'price': price,
            'tags': tags,
            'description': description,
            'media_urls': mediaUrls,
            'is_active': true,
          })
          .select()
          .single();

      return ServiceItem(
        id: result['id'],
        name: result['name'],
        price: result['price']?.toDouble() ?? 0.0,
        tags: List<String>.from(result['tags'] ?? []),
        description: result['description'] ?? '',
        media: (result['media_urls'] as List<dynamic>?)
                ?.map((url) => MediaItem(url: url, type: MediaType.image))
                .toList() ?? [],
      );
    } catch (e) {
      print('Error creating service: $e');
      return null;
    }
  }

  // Update service
  Future<bool> updateService(String serviceId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('services')
          .update(updates)
          .eq('id', serviceId);

      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  // Delete service
  Future<bool> deleteService(String serviceId) async {
    try {
      await _supabase
          .from('services')
          .delete()
          .eq('id', serviceId);

      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  // Toggle service active status
  Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await _supabase
          .from('services')
          .update({'is_active': isActive})
          .eq('id', serviceId);

      return true;
    } catch (e) {
      print('Error toggling service status: $e');
      return false;
    }
  }

  // Get all services for current vendor
  Future<List<ServiceItem>> getAllServices() async {
    try {
      final vendorId = await _getVendorId();
      if (vendorId == null) return [];

      final result = await _supabase
          .from('services')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return result.map((row) => ServiceItem(
        id: row['id'],
        name: row['name'],
        price: row['price']?.toDouble() ?? 0.0,
        tags: List<String>.from(row['tags'] ?? []),
        description: row['description'] ?? '',
        media: (row['media_urls'] as List<dynamic>?)
                ?.map((url) => MediaItem(url: url, type: MediaType.image))
                .toList() ?? [],
      )).toList();
    } catch (e) {
      print('Error getting all services: $e');
      return [];
    }
  }
}
