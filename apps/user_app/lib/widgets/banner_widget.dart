import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/banner_service.dart';
import 'dart:async';

class BannerWidget extends StatefulWidget {
  final double? aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackAsset;

  const BannerWidget({
    super.key,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset = 'assets/onboarding/onboarding_1.jpg',
  });

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  String? _bannerUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bannerUrl = await BannerService.getHeroBannerUrl();
      
      if (mounted) {
        setState(() {
          _bannerUrl = bannerUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading banner: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBannerContent() {
    // If we have a remote banner URL and it's not the fallback asset
    if (_bannerUrl != null && !_bannerUrl!.startsWith('assets/')) {
      return CachedNetworkImage(
        imageUrl: _bannerUrl!,
        fit: widget.fit,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Network image error: $error');
          return _buildFallbackImage();
        },
      );
    }

    // Fallback to local asset
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      widget.fallbackAsset,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Asset image error: $error');
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 48,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading
        ? Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : _buildBannerContent();

    if (widget.aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: content,
      );
    }

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

/// A smart banner widget that automatically handles single banner or carousel
class SmartBannerWidget extends StatefulWidget {
  final double? aspectRatio;
  final double? height;
  final BorderRadius? borderRadius;
  final Duration autoPlayDuration;
  final bool autoPlay;
  final String fallbackAsset;
  final BoxFit fit;

  const SmartBannerWidget({
    super.key,
    this.aspectRatio = 16 / 9,
    this.height,
    this.borderRadius,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.autoPlay = true,
    this.fallbackAsset = 'assets/onboarding/onboarding_1.jpg',
    this.fit = BoxFit.cover,
  });

  @override
  State<SmartBannerWidget> createState() => _SmartBannerWidgetState();
}

class _SmartBannerWidgetState extends State<SmartBannerWidget>
    with TickerProviderStateMixin {
  List<BannerItem> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  PageController? _pageController;
  Timer? _autoPlayTimer;
  bool _userInteracting = false;
  StreamSubscription? _bannerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBanners();
  }

  void _initializeBanners() {
    debugPrint('Initializing banner widget...');
    
    // Start real-time subscription
    BannerService.startBannerSubscription();
    
    // Listen to banner stream with better error handling
    _bannerSubscription = BannerService.getBannerStream().listen(
      (banners) {
        debugPrint('Banner widget received ${banners.length} banners');
        if (mounted) {
          setState(() {
            _banners = banners;
            _isLoading = false;
          });
          _setupCarousel();
        }
      },
      onError: (error) {
        debugPrint('Banner stream error: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // Try to refresh manually on error
        _refreshBanners();
      },
    );

    // Also fetch initial data as fallback
    _loadInitialBanners();
  }

  Future<void> _loadInitialBanners() async {
    try {
      debugPrint('Loading initial banners...');
      final banners = await BannerService.getActiveBanners();
      debugPrint('Loaded ${banners.length} initial banners');
      
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
        _setupCarousel();
      }
    } catch (e) {
      debugPrint('Error loading initial banners: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBanners() async {
    try {
      debugPrint('Manually refreshing banners...');
      await BannerService.refreshBanners();
    } catch (e) {
      debugPrint('Error refreshing banners: $e');
    }
  }

  void _setupCarousel() {
    _stopAutoPlay();
    
    if (_banners.length > 1 && widget.autoPlay) {
      _pageController ??= PageController();
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (!widget.autoPlay || _banners.length <= 1) return;
    
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (timer) {
      if (!mounted || _userInteracting || _pageController == null) return;
      
      final nextIndex = (_currentIndex + 1) % _banners.length;
      _pageController!.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _onUserInteractionStart() {
    setState(() {
      _userInteracting = true;
    });
    _stopAutoPlay();
  }

  void _onUserInteractionEnd() {
    setState(() {
      _userInteracting = false;
    });
    
    // Restart auto-play after a delay
    if (widget.autoPlay && _banners.length > 1) {
      Timer(const Duration(seconds: 2), () {
        if (mounted && !_userInteracting) {
          _startAutoPlay();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_banners.isEmpty) {
      // Fallback to local asset
      content = Image.asset(
        widget.fallbackAsset,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 48,
              ),
            ),
          );
        },
      );
    } else if (_banners.length == 1) {
      // Single banner
      content = CachedNetworkImage(
        imageUrl: _banners.first.getImageUrl(),
        fit: widget.fit,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          widget.fallbackAsset,
          fit: widget.fit,
        ),
      );
    } else {
      // Multiple banners carousel
      content = GestureDetector(
        onPanStart: (_) => _onUserInteractionStart(),
        onPanEnd: (_) => _onUserInteractionEnd(),
        onTapDown: (_) => _onUserInteractionStart(),
        onTapUp: (_) => _onUserInteractionEnd(),
        onTapCancel: () => _onUserInteractionEnd(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return CachedNetworkImage(
                  imageUrl: banner.getImageUrl(),
                  fit: widget.fit,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    widget.fallbackAsset,
                    fit: widget.fit,
                  ),
                );
              },
            ),
            
            // Page indicators
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _banners.asMap().entries.map((entry) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentIndex == entry.key ? 12 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Banner count indicator (top-right)
            if (_banners.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_banners.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Apply aspect ratio or height
    if (widget.height != null) {
      content = SizedBox(
        height: widget.height,
        child: content,
      );
    } else if (widget.aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: content,
      );
    }

    // Apply border radius
    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    // Wrap with refresh indicator for manual refresh capability
    return RefreshIndicator(
      onRefresh: _refreshBanners,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
          child: content,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController?.dispose();
    _bannerSubscription?.cancel();
    super.dispose();
  }
}

/// Legacy carousel widget for backward compatibility
class BannerCarousel extends StatefulWidget {
  final double height;
  final BorderRadius? borderRadius;
  final Duration autoPlayDuration;
  final bool autoPlay;

  const BannerCarousel({
    super.key,
    this.height = 200,
    this.borderRadius,
    this.autoPlayDuration = const Duration(seconds: 5),
    this.autoPlay = true,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  List<BannerItem> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await BannerService.getActiveBanners();
      
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });

        if (_banners.length > 1 && widget.autoPlay) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      debugPrint('Error loading banners: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoPlay() {
    _pageController = PageController();
    
    Future.delayed(widget.autoPlayDuration, () {
      if (mounted && _pageController != null) {
        _autoPlayNext();
      }
    });
  }

  void _autoPlayNext() {
    if (!mounted || _pageController == null || _banners.length <= 1) return;

    final nextIndex = (_currentIndex + 1) % _banners.length;
    
    _pageController!.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    Future.delayed(widget.autoPlayDuration, _autoPlayNext);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_banners.isEmpty) {
      // Fallback to single banner widget
      return SizedBox(
        height: widget.height,
        child: BannerWidget(
          borderRadius: widget.borderRadius,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_banners.length == 1) {
      // Single banner
      return SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: _banners.first.getImageUrl(),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => BannerWidget(
              borderRadius: widget.borderRadius,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // Multiple banners carousel
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return CachedNetworkImage(
                  imageUrl: banner.getImageUrl(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => BannerWidget(
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          
          // Page indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _banners.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}