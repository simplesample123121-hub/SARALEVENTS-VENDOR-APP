import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/service_models.dart';
import '../services/service_service.dart';
import '../core/session.dart';
import 'booking_screen.dart';


class CatalogScreen extends StatefulWidget {
  final String? selectedCategory;
  
  const CatalogScreen({super.key, this.selectedCategory});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ServiceService _serviceService;

  List<CategoryNode> _categories = <CategoryNode>[];
  List<ServiceItem> _services = <ServiceItem>[];
  String? _selectedCategoryId;
  bool _isLoading = true;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _serviceService = ServiceService(_supabase);
    _load();
    
    // If a category is pre-selected, set it
    if (widget.selectedCategory != null) {
      _selectedCategoryId = widget.selectedCategory;
    }
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final categories = await _serviceService.getAllCategories();
      List<ServiceItem> services;
      
      // If a category is pre-selected, filter services by vendor category
      if (widget.selectedCategory != null) {
        services = await _loadServicesByVendorCategory(widget.selectedCategory!);
        print('Loaded ${services.length} services for category: ${widget.selectedCategory}');
      } else {
        services = await _serviceService.getAllServices();
        print('Loaded ${services.length} services');
      }
      
      // Debug info
      print('Loaded ${categories.length} categories');
      if (services.isNotEmpty) {
        print('Sample service vendors: ${services.take(3).map((s) => s.vendorName).join(', ')}');
      }
      
      setState(() {
        _categories = categories;
        _services = services;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<List<ServiceItem>> _loadServicesByVendorCategory(String categoryName) async {
    try {
      print('Loading services for vendor category: $categoryName');
      
      // Fetch services from services table connected with vendor_profiles
      final response = await _supabase
          .from('services')
          .select('''
            id,
            name,
            description,
            price,
            vendor_id,
            vendor_profiles!inner(
              id,
              business_name,
              category
            )
          ''')
          .eq('vendor_profiles.category', categoryName)
          .limit(50);

      print('Raw response: $response');
      print('Response length: ${response.length}');

      final services = response.map((data) {
        print('Processing service data: $data');
        final vendorData = data['vendor_profiles'] as Map<String, dynamic>;
        print('Vendor data: $vendorData');
        
        return ServiceItem(
          id: data['id'].toString(),
          name: data['name'] ?? 'Unknown Service',
          price: (data['price'] ?? 0.0).toDouble(),
          description: data['description'] ?? 'Service from ${vendorData['business_name']}',
          tags: [], // Empty tags for now
          media: [], // Empty media for now
          vendorId: data['vendor_id']?.toString() ?? '',
          vendorName: vendorData['business_name'] ?? 'Unknown Vendor',
        );
      }).toList();

      print('Processed services: ${services.length}');
      return services;
    } catch (e) {
      print('Error fetching services from vendor profiles: $e');
      print('Error details: ${e.toString()}');
      return [];
    }
  }

  Future<void> _refresh() async {
    // If no category is selected and no search query, load all services
    if (_selectedCategoryId == null && widget.selectedCategory == null && _query.isEmpty) {
      await _load();
      return;
    }
    
    setState(() { _isLoading = true; });
    try {
      if (_query.isNotEmpty) {
        // If there's a search query, search services
        final results = await _serviceService.searchServices(_query);
        setState(() { _services = results; });
      } else if (widget.selectedCategory != null) {
        // If a category was pre-selected from home page, reload services for that category
        final results = await _loadServicesByVendorCategory(widget.selectedCategory!);
        setState(() { _services = results; });
      } else if (_selectedCategoryId != null) {
        // If a category was selected from the filter chips, get services for that category
        final results = await _serviceService.getServicesByCategory(_selectedCategoryId!);
        setState(() { _services = results; });
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Title section
            if (widget.selectedCategory != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDBB42).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFDBB42).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(widget.selectedCategory!),
                      color: const Color(0xFFFDBB42),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.selectedCategory} Services',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Services from ${widget.selectedCategory} vendors',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            
            // User profile section
            Consumer<UserSession>(
              builder: (context, session, _) {
                final user = session.currentUser;
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? 'User',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (value) {
                  _query = value.trim();
                  _refresh();
                },
              ),
            ),
            // Only show category filter if no specific category is pre-selected
            if (widget.selectedCategory == null)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == null;
                      return FilterChip(
                        label: const Text('All'),
                        selected: isSelected,
                        onSelected: (_) async {
                          setState(() { _selectedCategoryId = null; _query = ''; });
                          await _load();
                        },
                      );
                    }
                    final cat = _categories[index - 1];
                    final isSelected = _selectedCategoryId == cat.id;
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (_) async {
                        setState(() { _selectedCategoryId = cat.id; _query = ''; });
                        await _refresh();
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _categories.length + 1,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Error: $_error'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                      onRefresh: _refresh,
                      child: _services.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Center(child: Text('No services found')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemBuilder: (context, index) {
                                final s = _services[index];
                                return _buildServiceCard(context, s);
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemCount: _services.length,
                            ),
                      ),
            ),
           ],
         ),
       ),
     );
   }

  Widget _buildServiceCard(BuildContext context, ServiceItem service) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image Section
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFDBB42).withOpacity(0.1),
                    const Color(0xFFFDBB42).withOpacity(0.05),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Service Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBB42),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFDBB42).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getServiceIcon(service.name),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Price Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFDBB42),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            service.price.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Service Details Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name and Vendor
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service.vendorName.isNotEmpty ? service.vendorName : 'Vendor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Description
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Tags
                  if (service.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: service.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDBB42).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFFDBB42).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFDBB42),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  // Book Now Button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(service: service),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDBB42),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        shadowColor: const Color(0xFFFDBB42).withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('photography')) return Icons.camera_alt;
    if (name.contains('decoration')) return Icons.local_florist;
    if (name.contains('catering')) return Icons.restaurant;
    if (name.contains('farmhouse')) return Icons.home;
    if (name.contains('music') || name.contains('dj')) return Icons.music_note;
    if (name.contains('venue')) return Icons.location_on;
    if (name.contains('event essentials')) return Icons.event;
    return Icons.category;
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('photography') || name.contains('photo') || name.contains('camera')) {
      return Icons.camera_alt;
    } else if (name.contains('catering') || name.contains('food') || name.contains('meal')) {
      return Icons.restaurant;
    } else if (name.contains('decoration') || name.contains('decor') || name.contains('flower')) {
      return Icons.local_florist;
    } else if (name.contains('music') || name.contains('dj') || name.contains('sound')) {
      return Icons.music_note;
    } else if (name.contains('venue') || name.contains('hall') || name.contains('place')) {
      return Icons.location_on;
    } else if (name.contains('transport') || name.contains('car') || name.contains('vehicle')) {
      return Icons.directions_car;
    } else if (name.contains('makeup') || name.contains('beauty') || name.contains('salon')) {
      return Icons.face;
    } else if (name.contains('dress') || name.contains('clothing') || name.contains('suit')) {
      return Icons.checkroom;
    } else {
      return Icons.miscellaneous_services;
    }
  }
}
