import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/wishlist_notifier.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WishlistButton extends StatefulWidget {
  final String serviceId;
  final double size;
  final VoidCallback? onToggle;

  const WishlistButton({
    super.key, 
    required this.serviceId, 
    this.size = 36,
    this.onToggle,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize wishlist if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WishlistNotifier.instance.wishlistIds.isEmpty && 
          !WishlistNotifier.instance.isLoading) {
        WishlistNotifier.instance.initialize();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isToggling) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to use wishlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        GoRouter.of(context).push('/auth/pre');
      }
      return;
    }

    setState(() { _isToggling = true; });
    
    // Animate the button
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      final success = await WishlistNotifier.instance.toggleWishlist(widget.serviceId);
      
      if (mounted) {
        final message = success 
            ? 'Added to wishlist' 
            : 'Removed from wishlist';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        widget.onToggle?.call();
      }
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
    } finally {
      if (mounted) {
        setState(() { _isToggling = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WishlistNotifier.instance,
      builder: (context, _) {
        final isInWishlist = WishlistNotifier.instance.isInWishlist(widget.serviceId);
        final isLoading = WishlistNotifier.instance.isLoading;
        final size = widget.size;
        final iconSize = size * 0.55;
        
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggle,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: (_isToggling || isLoading)
                        ? SizedBox(
                            width: 18, 
                            height: 18, 
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isInWishlist 
                                    ? const Color(0xFFA51414) 
                                    : Colors.grey,
                              ),
                            ),
                          )
                        : SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: isInWishlist
                                ? Icon(
                                    Icons.favorite,
                                    color: const Color(0xFFA51414),
                                    size: iconSize,
                                  )
                                : SvgPicture.asset(
                                    'assets/icons/wishlist_icon.svg',
                                    width: iconSize,
                                    height: iconSize,
                                    colorFilter: ColorFilter.mode(
                                      Colors.grey.shade600,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
