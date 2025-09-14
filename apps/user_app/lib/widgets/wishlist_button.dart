import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../core/wishlist_notifier.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WishlistButton extends StatefulWidget {
  final String serviceId;
  final double size;

  const WishlistButton({super.key, required this.serviceId, this.size = 36});

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  bool _liked = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final service = ProfileService(Supabase.instance.client);
      final ids = await service.getWishlistServiceIds(user.id);
      if (!mounted) return;
      setState(() { _liked = ids.contains(widget.serviceId); });
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (_loading) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to use wishlist')));
        GoRouter.of(context).push('/auth/pre');
      }
      return;
    }
    setState(() { _loading = true; });
    try {
      final service = ProfileService(Supabase.instance.client);
      final updated = await service.toggleWishlist(userId: user.id, serviceId: widget.serviceId);
      if (!mounted) return;
      setState(() { _liked = updated.contains(widget.serviceId); });
      // Broadcast a change so listeners update immediately
      WishlistNotifier.instance.emitChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update wishlist: $e')));
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final iconSize = size * 0.55;
    return Material(
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: _liked
                      ? Icon(
                          Icons.favorite,
                          color: const Color(0xFFA51414),
                          size: iconSize,
                        )
                      : SvgPicture.asset(
                          'assets/icons/wishlist_icon.svg',
                          width: iconSize,
                          height: iconSize,
                        ),
                ),
        ),
      ),
    );
  }
}
