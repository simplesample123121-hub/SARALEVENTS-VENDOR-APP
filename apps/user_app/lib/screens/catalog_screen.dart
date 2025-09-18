import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_models.dart';
import '../services/service_service.dart';
import 'service_details_screen.dart';
import '../widgets/wishlist_button.dart';


class CatalogScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? eventType;
  final String? categoryDisplayName;
  
  const CatalogScreen({
    super.key, 
    this.selectedCategory, 
    this.eventType,
    this.categoryDisplayName,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ServiceService _serviceService;

  List<ServiceItem> _services = <ServiceItem>[]; // filtered view
  List<ServiceItem> _allServices = <ServiceItem>[]; // original
  String? _selectedCategoryId;
  bool _isLoading = true;
  String _query = '';
  String? _error;

  // Filters
  double? _minPrice;
  double? _maxPrice;
  double? _currentMinPrice;
  double? _currentMaxPrice;
  double _minRating = 0; // visual only, because we don't have ratings in schema

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
        _allServices = services;
        // init price bounds
        final prices = _allServices.map((s) => s.price).where((p) => p.isFinite).toList();
        if (prices.isNotEmpty) {
          prices.sort();
          _minPrice = prices.first;
          _maxPrice = prices.last;
          _currentMinPrice = _minPrice;
          _currentMaxPrice = _maxPrice;
        }
        _applyFilters();
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
      // Direct fetch (no cache) to reflect latest changes immediately
      final response = await _supabase
          .from('services')
          .select('''
            id,
            name,
            description,
            price,
            media_urls,
            vendor_id,
            capacity_min,
            capacity_max,
            rating_avg,
            rating_count,
            parking_spaces,
            suited_for,
            features,
            policies,
            vendor_profiles!inner(
              id,
              business_name
            )
          ''')
          .eq('category', categoryName)
          .eq('is_active', true)
          .eq('is_visible_to_users', true)
          .order('created_at', ascending: false)
          .limit(100);

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
          tags: [],
          media: (data['media_urls'] as List<dynamic>?)
                  ?.map((url) => MediaItem(url: url.toString(), type: MediaType.image))
                  .toList() ??
              [],
          vendorId: data['vendor_id']?.toString() ?? '',
          vendorName: vendorData['business_name'] ?? 'Unknown Vendor',
          capacityMin: data['capacity_min'] as int?,
          capacityMax: data['capacity_max'] as int?,
          parkingSpaces: data['parking_spaces'] as int?,
          ratingAvg: (data['rating_avg'] is num) ? (data['rating_avg'] as num).toDouble() : null,
          ratingCount: data['rating_count'] as int?,
          suitedFor: List<String>.from((data['suited_for'] as List<dynamic>?) ?? const <String>[]),
          features: (data['features'] is Map<String, dynamic>)
              ? (data['features'] as Map<String, dynamic>)
              : const <String, dynamic>{},
          policies: List<String>.from((data['policies'] as List<dynamic>?) ?? const <String>[]),
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
        // client-side search for responsiveness
        setState(() {
          _services = _allServices
              .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
        });
      } else if (widget.selectedCategory != null) {
        // If a category was pre-selected from home page, reload services for that category
        final results = await _loadServicesByVendorCategory(widget.selectedCategory!);
        setState(() { _allServices = results; });
        _applyFilters();
      } else if (_selectedCategoryId != null) {
        // If a category was selected from the filter chips, get services for that category
        final results = await _serviceService.getServicesByCategory(_selectedCategoryId!);
        setState(() { _allServices = results; });
        _applyFilters();
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _applyFilters() {
    var list = List<ServiceItem>.from(_allServices);
    // price filter
    if (_currentMinPrice != null && _currentMaxPrice != null) {
      list = list
          .where((s) => s.price >= _currentMinPrice! && s.price <= _currentMaxPrice!)
          .toList();
    }
    // rating filter (visual only, use 4.5 as placeholder)
    final placeholderRating = 4.5;
    list = list.where((_) => placeholderRating >= _minRating).toList();
    // query filter if any
    if (_query.isNotEmpty) {
      list = list.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    _services = list;
  }

  void _openFilterSheet() {
    final minP = _minPrice ?? 0;
    final maxP = _maxPrice ?? 100000;
    double tempMin = _currentMinPrice ?? minP;
    double tempMax = _currentMaxPrice ?? maxP;
    double tempRating = _minRating;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Price range'),
                RangeSlider(
                  values: RangeValues(tempMin.clamp(minP, maxP), tempMax.clamp(minP, maxP)),
                  min: minP,
                  max: maxP,
                  divisions: 20,
                  labels: RangeLabels('₹${tempMin.toStringAsFixed(0)}', '₹${tempMax.toStringAsFixed(0)}'),
                  onChanged: (v) => setLocal(() { tempMin = v.start; tempMax = v.end; }),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Min: ₹${tempMin.toStringAsFixed(0)}'),
                    Text('Max: ₹${tempMax.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Rating'),
                Slider(
                  value: tempRating,
                  onChanged: (v) => setLocal(() { tempRating = v; }),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: '${tempRating.toStringAsFixed(1)}+',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _currentMinPrice = tempMin;
                        _currentMaxPrice = tempMax;
                        _minRating = tempRating;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply filters'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedCategory != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.selectedCategory!,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Explore vendor\'s section', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          _query = value.trim();
                          setState(() { _applyFilters(); });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: Colors.grey),
                      onPressed: () {
                        _openFilterSheet();
                      },
                    )
                  ],
                ),
              ),
            ),
            // category chips removed per request
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
                              : GridView.builder(
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
                                    return _buildGridServiceCard(context, s);
                                  },
                                ),
                        ),
            ),
           ],
         ),
       ),
     );
   }

  Widget _buildGridServiceCard(BuildContext context, ServiceItem service) {
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
