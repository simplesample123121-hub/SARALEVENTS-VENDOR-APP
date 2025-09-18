import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/wishlist_service.dart';

class WishlistNotifier extends ChangeNotifier {
  WishlistNotifier._();
  static final WishlistNotifier instance = WishlistNotifier._();

  late final WishlistService _wishlistService;
  Set<String> _wishlistIds = <String>{};
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  Set<String> get wishlistIds => Set.unmodifiable(_wishlistIds);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _initialized;

  bool isInWishlist(String serviceId) => _wishlistIds.contains(serviceId);
  int get count => _wishlistIds.length;

  void _initializeService() {
    if (!_initialized) {
      _wishlistService = WishlistService(Supabase.instance.client);
      _initialized = true;
    }
  }

  Future<void> initialize() async {
    _initializeService();
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _wishlistIds.clear();
      _error = null;
      notifyListeners();
      return;
    }

    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ids = await _wishlistService.getWishlistIds(user.id);
      _wishlistIds = Set<String>.from(ids);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Wishlist initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleWishlist(String serviceId) async {
    _initializeService();
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Optimistic update
    final wasInWishlist = _wishlistIds.contains(serviceId);
    if (wasInWishlist) {
      _wishlistIds.remove(serviceId);
    } else {
      _wishlistIds.add(serviceId);
    }
    notifyListeners();

    try {
      final newState = await _wishlistService.toggleWishlist(user.id, serviceId);
      
      // Update state based on actual result
      if (newState && !_wishlistIds.contains(serviceId)) {
        _wishlistIds.add(serviceId);
      } else if (!newState && _wishlistIds.contains(serviceId)) {
        _wishlistIds.remove(serviceId);
      }
      
      _error = null;
      notifyListeners();
      return newState;
    } catch (e) {
      // Revert optimistic update on error
      if (wasInWishlist) {
        _wishlistIds.add(serviceId);
      } else {
        _wishlistIds.remove(serviceId);
      }
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addToWishlist(String serviceId) async {
    _initializeService();
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (_wishlistIds.contains(serviceId)) return;

    // Optimistic update
    _wishlistIds.add(serviceId);
    notifyListeners();

    try {
      await _wishlistService.addToWishlist(user.id, serviceId);
      _error = null;
    } catch (e) {
      // Revert on error
      _wishlistIds.remove(serviceId);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String serviceId) async {
    _initializeService();
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (!_wishlistIds.contains(serviceId)) return;

    // Optimistic update
    _wishlistIds.remove(serviceId);
    notifyListeners();

    try {
      await _wishlistService.removeFromWishlist(user.id, serviceId);
      _error = null;
    } catch (e) {
      // Revert on error
      _wishlistIds.add(serviceId);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearWishlist() async {
    _initializeService();
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final backup = Set<String>.from(_wishlistIds);
    
    // Optimistic update
    _wishlistIds.clear();
    notifyListeners();

    try {
      await _wishlistService.clearWishlist(user.id);
      _error = null;
    } catch (e) {
      // Revert on error
      _wishlistIds = backup;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    _wishlistIds.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void emitChanged() {
    notifyListeners();
  }
}
