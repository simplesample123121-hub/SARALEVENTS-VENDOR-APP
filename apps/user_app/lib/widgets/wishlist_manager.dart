import 'package:flutter/material.dart';
import '../core/wishlist_notifier.dart';

/// A widget that provides wishlist management functionality to its children
class WishlistManager extends StatefulWidget {
  final Widget child;

  const WishlistManager({
    super.key,
    required this.child,
  });

  @override
  State<WishlistManager> createState() => _WishlistManagerState();
}

class _WishlistManagerState extends State<WishlistManager> {
  @override
  void initState() {
    super.initState();
    // Initialize wishlist when the manager is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!WishlistNotifier.instance.isInitialized) {
        WishlistNotifier.instance.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A mixin that provides wishlist functionality to widgets
mixin WishlistMixin<T extends StatefulWidget> on State<T> {
  bool isInWishlist(String serviceId) {
    return WishlistNotifier.instance.isInWishlist(serviceId);
  }

  Future<void> toggleWishlist(String serviceId) async {
    try {
      await WishlistNotifier.instance.toggleWishlist(serviceId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> addToWishlist(String serviceId) async {
    try {
      await WishlistNotifier.instance.addToWishlist(serviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to wishlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to wishlist: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> removeFromWishlist(String serviceId) async {
    try {
      await WishlistNotifier.instance.removeFromWishlist(serviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from wishlist: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// A utility class for wishlist operations
class WishlistUtils {
  static bool isInWishlist(String serviceId) {
    return WishlistNotifier.instance.isInWishlist(serviceId);
  }

  static int get count => WishlistNotifier.instance.count;

  static Set<String> get allIds => WishlistNotifier.instance.wishlistIds;

  static Future<void> initialize() async {
    await WishlistNotifier.instance.initialize();
  }

  static Future<bool> toggle(String serviceId) async {
    return await WishlistNotifier.instance.toggleWishlist(serviceId);
  }

  static Future<void> add(String serviceId) async {
    await WishlistNotifier.instance.addToWishlist(serviceId);
  }

  static Future<void> remove(String serviceId) async {
    await WishlistNotifier.instance.removeFromWishlist(serviceId);
  }

  static Future<void> clear() async {
    await WishlistNotifier.instance.clearWishlist();
  }

  static void reset() {
    WishlistNotifier.instance.reset();
  }
}