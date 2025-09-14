import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_models.dart';
import '../services/service_service.dart';
import '../services/profile_service.dart';
import 'service_details_screen.dart';
import '../widgets/wishlist_button.dart';
import '../core/wishlist_notifier.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ServiceService _serviceService;
  late final ProfileService _profileService;

  bool _loading = true;
  String? _error;
  List<ServiceItem> _services = <ServiceItem>[];
  VoidCallback? _wishlistListener;

  @override
  void initState() {
    super.initState();
    _serviceService = ServiceService(_supabase);
    _profileService = ProfileService(_supabase);
    _load();
    _wishlistListener = () {
      _load();
    };
    WishlistNotifier.instance.addListener(_wishlistListener!);
  }

  @override
  void dispose() {
    if (_wishlistListener != null) {
      WishlistNotifier.instance.removeListener(_wishlistListener!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() { _services = <ServiceItem>[]; });
      } else {
        final ids = await _profileService.getWishlistServiceIds(user.id);
        final items = await _serviceService.getServicesByIds(ids);
        setState(() { _services = items; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: const [
                  Icon(Icons.favorite, color: Color(0xFFA51414)),
                  SizedBox(width: 8),
                  Text('Wish List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('My Wishlist', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _services.isEmpty
                          ? ListView(children: const [SizedBox(height: 120), Icon(Icons.favorite_border, size: 48, color: Colors.grey), SizedBox(height: 8), Center(child: Text('No items in your wishlist'))])
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.70,
                                ),
                                itemCount: _services.length,
                                itemBuilder: (context, index) {
                                  final s = _services[index];
                                  return _wishlistCard(context, s);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishlistCard(BuildContext context, ServiceItem service) {
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ServiceDetailsScreen(service: service)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 12,
                      child: (service.media.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: Uri.encodeFull(service.media.first.url),
                              fit: BoxFit.cover,
                              placeholder: (c, _) => Container(color: Colors.black12.withOpacity(0.06)),
                              errorWidget: (c, _, __) => Container(color: Colors.black12.withOpacity(0.06)),
                            )
                          : Container(color: Colors.black12.withOpacity(0.06)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('Capacity - 0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹ ${service.price.toStringAsFixed(0)}/-', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Row(children: const [Icon(Icons.star, size: 14, color: Color(0xFFFFC107)), SizedBox(width: 4), Text('4.5k')]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: WishlistButton(serviceId: service.id, size: 38),
        ),
      ],
    );
  }
}
