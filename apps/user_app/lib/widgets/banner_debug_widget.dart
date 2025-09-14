import 'package:flutter/material.dart';
import '../services/banner_service.dart';
import 'dart:async';

/// Debug widget to test banner real-time functionality
class BannerDebugWidget extends StatefulWidget {
  const BannerDebugWidget({super.key});

  @override
  State<BannerDebugWidget> createState() => _BannerDebugWidgetState();
}

class _BannerDebugWidgetState extends State<BannerDebugWidget> {
  List<BannerItem> _banners = [];
  bool _isLoading = false;
  String _status = 'Not connected';
  StreamSubscription? _bannerSubscription;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    setState(() {
      _status = 'Connecting...';
      _isLoading = true;
    });

    // Start the banner service
    BannerService.startBannerSubscription();

    // Listen to updates
    _bannerSubscription = BannerService.getBannerStream().listen(
      (banners) {
        if (mounted) {
          setState(() {
            _banners = banners;
            _isLoading = false;
            _status = 'Connected - Real-time active';
            _updateCount++;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _status = 'Error: $error';
          });
        }
      },
    );

    // Also fetch initial data
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final banners = await BannerService.getActiveBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
          if (_status == 'Connecting...') {
            _status = 'Connected - Polling mode';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Error fetching: $e';
        });
      }
    }
  }

  Future<void> _manualRefresh() async {
    setState(() {
      _isLoading = true;
    });
    
    await BannerService.refreshBanners();
    await _fetchBanners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _status.contains('Connected') 
                              ? Icons.check_circle 
                              : _status.contains('Error')
                                  ? Icons.error
                                  : Icons.hourglass_empty,
                          color: _status.contains('Connected') 
                              ? Colors.green 
                              : _status.contains('Error')
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Updates received: $_updateCount'),
                    Text('Banners count: ${_banners.length}'),
                    if (_isLoading) 
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Banner list
            Text(
              'Active Banners',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _banners.isEmpty
                  ? const Center(
                      child: Text('No banners found'),
                    )
                  : ListView.builder(
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Card(
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                banner.getImageUrl(),
                                width: 60,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 40,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.error),
                                  );
                                },
                              ),
                            ),
                            title: Text(banner.assetName),
                            subtitle: Text(banner.description),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  banner.isActive 
                                      ? Icons.visibility 
                                      : Icons.visibility_off,
                                  color: banner.isActive 
                                      ? Colors.green 
                                      : Colors.grey,
                                ),
                                Text(
                                  banner.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: banner.isActive 
                                        ? Colors.green 
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _manualRefresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _bannerSubscription?.cancel();
    BannerService.stopBannerSubscription();
    super.dispose();
  }
}