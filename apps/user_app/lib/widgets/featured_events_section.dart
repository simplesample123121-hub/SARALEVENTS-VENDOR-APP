import 'package:flutter/material.dart';
import '../models/service_models.dart';
import '../services/featured_services_service.dart';
import '../widgets/featured_event_card.dart';
import 'dart:async';

class FeaturedEventsSection extends StatefulWidget {
  final VoidCallback? onSeeAllTap;
  final Function(ServiceItem)? onServiceTap;

  const FeaturedEventsSection({
    super.key,
    this.onSeeAllTap,
    this.onServiceTap,
  });

  @override
  State<FeaturedEventsSection> createState() => _FeaturedEventsSectionState();
}

class _FeaturedEventsSectionState extends State<FeaturedEventsSection>
    with AutomaticKeepAliveClientMixin {
  List<ServiceItem> _featuredServices = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _servicesSubscription;
  // int _updateCount = 0; // COMMENTED OUT

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeFeaturedServices();
  }

  void _initializeFeaturedServices() {
    debugPrint('Initializing featured services...');
    
    // Start real-time subscription
    FeaturedServicesService.startFeaturedServicesSubscription();
    
    // Listen to services stream
    _servicesSubscription = FeaturedServicesService.getFeaturedServicesStream().listen(
      (services) {
        debugPrint('Featured services widget received ${services.length} services');
        if (mounted) {
          setState(() {
            _featuredServices = services.take(6).toList(); // Limit to 6 for UI
            _isLoading = false;
            _error = null;
            // _updateCount++; // COMMENTED OUT
          });
        }
      },
      onError: (error) {
        debugPrint('Featured services stream error: $error');
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        }
        // Try to refresh manually on error
        _refreshServices();
      },
    );

    // Also fetch initial data as fallback
    _loadInitialServices();
  }

  Future<void> _loadInitialServices() async {
    try {
      debugPrint('Loading initial featured services...');
      final services = await FeaturedServicesService.getFeaturedServices(limit: 6);
      debugPrint('Loaded ${services.length} initial featured services');
      
      if (mounted) {
        setState(() {
          _featuredServices = services;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial featured services: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshServices() async {
    try {
      debugPrint('Manually refreshing featured services...');
      await FeaturedServicesService.refreshFeaturedServices();
    } catch (e) {
      debugPrint('Error refreshing featured services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Events',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Update counter - COMMENTED OUT
                  // if (_updateCount > 0)
                  //   Text(
                  //     'Updated $_updateCount time${_updateCount > 1 ? 's' : ''}',
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: Colors.green.shade600,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                ],
              ),
              GestureDetector(
                onTap: widget.onSeeAllTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Services list
        SizedBox(
          height: 210,
          child: _buildServicesContent(),
        ),
      ],
    );
  }

  Widget _buildServicesContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_featuredServices.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildServicesList();
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return Container(
          width: 170,
          height: 210,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey.shade400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading services',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _refreshServices();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDBB42),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              color: Colors.grey.shade400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No featured services available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new services',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    return RefreshIndicator(
      onRefresh: _refreshServices,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _featuredServices.length,
        itemBuilder: (context, index) {
          final service = _featuredServices[index];
          return FeaturedEventCard(
            service: service,
            width: 170,
            height: 210,
            onTap: () => widget.onServiceTap?.call(service),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    // Don't stop the service subscription here as other widgets might be using it
    super.dispose();
  }
}