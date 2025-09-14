import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_models.dart';
import 'dart:async';

class FeaturedServicesService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static StreamSubscription? _servicesSubscription;
  static Timer? _pollingTimer;
  static final StreamController<List<ServiceItem>> _servicesStreamController = 
      StreamController<List<ServiceItem>>.broadcast();
  static List<ServiceItem> _lastKnownServices = [];
  static bool _isSubscriptionActive = false;

  /// Get a stream of featured services updates for real-time changes
  static Stream<List<ServiceItem>> getFeaturedServicesStream() {
    return _servicesStreamController.stream;
  }

  /// Fetch featured services from the database
  static Future<List<ServiceItem>> getFeaturedServices({int limit = 12}) async {
    try {
      debugPrint('Fetching featured services...');
      
      final result = await _supabase
          .from('services')
          .select('''
            *,
            vendor_profiles!inner(
              business_name,
              id
            )
          ''')
          .eq('is_active', true)
          .eq('is_visible_to_users', true)
          .eq('is_featured', true)
          .order('updated_at', ascending: false)
          .limit(limit);

      final services = (result as List<dynamic>).map((row) {
        final vendorData = row['vendor_profiles'] as Map<String, dynamic>?;
        
        return ServiceItem(
          id: row['id'],
          categoryId: row['category_id'],
          name: row['name'],
          price: (row['price'] ?? 0).toDouble(),
          tags: List<String>.from(row['tags'] ?? []),
          description: row['description'] ?? '',
          media: (row['media_urls'] as List<dynamic>?)
                  ?.map((url) => MediaItem(url: url.toString(), type: MediaType.image))
                  .toList() ?? [],
          vendorId: row['vendor_id'] ?? '',
          vendorName: vendorData?['business_name'] ?? 'Unknown Vendor',
          ratingAvg: (row['rating_avg'] ?? 0).toDouble(),
          ratingCount: row['rating_count'] ?? 0,
          capacityMin: row['capacity_min'],
          capacityMax: row['capacity_max'],
          suitedFor: List<String>.from(row['suited_for'] ?? []),
          features: Map<String, dynamic>.from(row['features'] ?? {}),
        );
      }).toList();

      debugPrint('Loaded ${services.length} featured services');
      return services;
    } catch (e) {
      debugPrint('Error fetching featured services: $e');
      return [];
    }
  }

  /// Start listening for real-time featured services updates
  static void startFeaturedServicesSubscription() {
    if (_isSubscriptionActive) return;
    
    debugPrint('Starting featured services subscription...');
    _isSubscriptionActive = true;
    
    // Cancel existing subscriptions
    _servicesSubscription?.cancel();
    _pollingTimer?.cancel();

    // Try real-time subscription first
    _setupRealtimeSubscription();
    
    // Also start polling as backup (every 15 seconds)
    _startPolling();

    // Fetch initial data immediately
    _fetchAndUpdateServices();
  }

  static void _setupRealtimeSubscription() {
    try {
      debugPrint('Setting up real-time subscription for featured services...');
      
      // Subscribe to real-time changes on services table
      _servicesSubscription = _supabase
          .from('services')
          .stream(primaryKey: ['id'])
          .listen(
            (data) {
              debugPrint('Received real-time services update: ${data.length} records');
              _processStreamData(data);
            },
            onError: (error) {
              debugPrint('Real-time services subscription error: $error');
              // Real-time failed, rely on polling
            },
          );
    } catch (e) {
      debugPrint('Failed to setup real-time services subscription: $e');
      // Continue with polling only
    }
  }

  static void _processStreamData(List<dynamic> data) {
    try {
      // Filter for featured services only
      final featuredData = data.where((json) => 
          json['is_active'] == true && 
          json['is_visible_to_users'] == true && 
          json['is_featured'] == true).toList();
      
      if (featuredData.isNotEmpty) {
        debugPrint('Processing ${featuredData.length} featured services from stream');
        _fetchAndUpdateServices(); // Fetch with vendor data
      }
    } catch (e) {
      debugPrint('Error processing services stream data: $e');
      // Fallback to direct fetch
      _fetchAndUpdateServices();
    }
  }

  static void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isSubscriptionActive) {
        _fetchAndUpdateServices();
      } else {
        timer.cancel();
      }
    });
  }

  static Future<void> _fetchAndUpdateServices() async {
    try {
      final services = await getFeaturedServices(limit: 12);
      
      // Only update if services actually changed
      if (!_servicesEqual(services, _lastKnownServices)) {
        debugPrint('Featured services changed, updating stream...');
        _lastKnownServices = services;
        _servicesStreamController.add(services);
      }
    } catch (e) {
      debugPrint('Error fetching services for update: $e');
      _servicesStreamController.addError(e);
    }
  }

  static bool _servicesEqual(List<ServiceItem> a, List<ServiceItem> b) {
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || 
          a[i].name != b[i].name || 
          a[i].price != b[i].price) {
        return false;
      }
    }
    return true;
  }

  /// Stop listening for real-time services updates
  static void stopFeaturedServicesSubscription() {
    debugPrint('Stopping featured services subscription...');
    _isSubscriptionActive = false;
    _servicesSubscription?.cancel();
    _servicesSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Force refresh services (useful for manual refresh)
  static Future<void> refreshFeaturedServices() async {
    debugPrint('Force refreshing featured services...');
    await _fetchAndUpdateServices();
  }

  /// Dispose resources
  static void dispose() {
    stopFeaturedServicesSubscription();
    _servicesStreamController.close();
  }
}