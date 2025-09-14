import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class BannerItem {
  final String id;
  final String assetName;
  final String assetPath;
  final String bucketName;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  BannerItem({
    required this.id,
    required this.assetName,
    required this.assetPath,
    required this.bucketName,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'],
      assetName: json['asset_name'],
      assetPath: json['asset_path'],
      bucketName: json['bucket_name'],
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String getImageUrl() {
    final supabase = Supabase.instance.client;
    return supabase.storage
        .from(bucketName)
        .getPublicUrl(assetPath);
  }
}

class BannerService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static StreamSubscription? _bannerSubscription;
  static Timer? _pollingTimer;
  static final StreamController<List<BannerItem>> _bannerStreamController = 
      StreamController<List<BannerItem>>.broadcast();
  static List<BannerItem> _lastKnownBanners = [];
  static bool _isSubscriptionActive = false;

  /// Fetch active banners for the user app
  static Future<List<BannerItem>> getActiveBanners() async {
    try {
      final response = await _supabase
          .from('app_assets')
          .select('*')
          .eq('app_type', 'user')
          .eq('asset_type', 'banner')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => BannerItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      return [];
    }
  }

  /// Fetch a specific banner by name
  static Future<BannerItem?> getBannerByName(String assetName) async {
    try {
      final response = await _supabase
          .from('app_assets')
          .select('*')
          .eq('app_type', 'user')
          .eq('asset_type', 'banner')
          .eq('asset_name', assetName)
          .eq('is_active', true)
          .single();

      return BannerItem.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching banner by name: $e');
      return null;
    }
  }

  /// Get the hero banner (first active banner or fallback)
  static Future<String> getHeroBannerUrl() async {
    try {
      // Try to get a specific hero banner first
      final heroBanner = await getBannerByName('hero_banner');
      if (heroBanner != null) {
        return heroBanner.getImageUrl();
      }

      // Fallback to first active banner
      final banners = await getActiveBanners();
      if (banners.isNotEmpty) {
        return banners.first.getImageUrl();
      }

      // Ultimate fallback to local asset
      return 'assets/onboarding/onboarding_1.jpg';
    } catch (e) {
      debugPrint('Error getting hero banner URL: $e');
      return 'assets/onboarding/onboarding_1.jpg';
    }
  }

  /// Check if remote banners are available
  static Future<bool> hasRemoteBanners() async {
    try {
      final banners = await getActiveBanners();
      return banners.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get a stream of banner updates for real-time changes
  static Stream<List<BannerItem>> getBannerStream() {
    return _bannerStreamController.stream;
  }

  /// Start listening for real-time banner updates
  static void startBannerSubscription() {
    if (_isSubscriptionActive) return;
    
    debugPrint('Starting banner subscription...');
    _isSubscriptionActive = true;
    
    // Cancel existing subscriptions
    _bannerSubscription?.cancel();
    _pollingTimer?.cancel();

    // Try real-time subscription first
    _setupRealtimeSubscription();
    
    // Also start polling as backup (every 10 seconds)
    _startPolling();

    // Fetch initial data immediately
    _fetchAndUpdateBanners();
  }

  static void _setupRealtimeSubscription() {
    try {
      debugPrint('Setting up real-time subscription for banners...');
      
      // Subscribe to real-time changes on app_assets table
      _bannerSubscription = _supabase
          .from('app_assets')
          .stream(primaryKey: ['id'])
          .listen(
            (data) {
              debugPrint('Received real-time banner update: ${data.length} records');
              _processStreamData(data);
            },
            onError: (error) {
              debugPrint('Real-time subscription error: $error');
              // Real-time failed, rely on polling
            },
          );
    } catch (e) {
      debugPrint('Failed to setup real-time subscription: $e');
      // Continue with polling only
    }
  }

  static void _processStreamData(List<dynamic> data) {
    try {
      final banners = data
          .where((json) => 
              json['app_type'] == 'user' && 
              json['asset_type'] == 'banner' && 
              json['is_active'] == true)
          .map((json) => BannerItem.fromJson(json))
          .toList();
      
      // Sort by creation date (newest first)
      banners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Only update if banners actually changed
      if (!_bannersEqual(banners, _lastKnownBanners)) {
        debugPrint('Banner list changed, updating stream...');
        _lastKnownBanners = banners;
        _bannerStreamController.add(banners);
      }
    } catch (e) {
      debugPrint('Error processing banner stream data: $e');
      // Fallback to direct fetch
      _fetchAndUpdateBanners();
    }
  }

  static void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isSubscriptionActive) {
        _fetchAndUpdateBanners();
      } else {
        timer.cancel();
      }
    });
  }

  static Future<void> _fetchAndUpdateBanners() async {
    try {
      final banners = await getActiveBanners();
      
      // Only update if banners actually changed
      if (!_bannersEqual(banners, _lastKnownBanners)) {
        debugPrint('Fetched banners changed, updating stream...');
        _lastKnownBanners = banners;
        _bannerStreamController.add(banners);
      }
    } catch (e) {
      debugPrint('Error fetching banners for update: $e');
      _bannerStreamController.addError(e);
    }
  }

  static bool _bannersEqual(List<BannerItem> a, List<BannerItem> b) {
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].isActive != b[i].isActive) {
        return false;
      }
    }
    return true;
  }

  /// Stop listening for real-time banner updates
  static void stopBannerSubscription() {
    debugPrint('Stopping banner subscription...');
    _isSubscriptionActive = false;
    _bannerSubscription?.cancel();
    _bannerSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Force refresh banners (useful for manual refresh)
  static Future<void> refreshBanners() async {
    debugPrint('Force refreshing banners...');
    await _fetchAndUpdateBanners();
  }

  /// Dispose resources
  static void dispose() {
    stopBannerSubscription();
    _bannerStreamController.close();
  }
}