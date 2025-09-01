import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'service_models.dart';
import '../../core/ui/widgets.dart';
import '../../core/ui/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'service_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  late final CategoryNode _root;
  final List<CategoryNode> _stack = <CategoryNode>[];
  final ServiceService _serviceService = ServiceService();
  bool _isLoading = false;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late final TabController _tabController;

  CategoryNode get _current => _stack.isEmpty ? _root : _stack.last;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _root = CategoryNode(id: 'root', name: 'All', subcategories: []);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _serviceService.getCategories();
      final rootServices = await _serviceService.getRootServices();
      setState(() {
        _root.subcategories = categories;
        _root.services
          ..clear()
          ..addAll(rootServices);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServicesFor(CategoryNode node) async {
    try {
      final items = await _serviceService.getServices(node.id);
      if (!mounted) return;
      setState(() {
        node.services
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      print('Error loading services for category ${node.id}: $e');
    }
  }

  // Get all services with category names for tabs
  Future<List<Map<String, dynamic>>> _getAllServicesWithCategories() async {
    try {
      final allServices = await _serviceService.getAllServicesWithStatus();
      final categories = await _serviceService.getCategories();
      
      // Create a map for quick category lookup
      final categoryMap = <String, String>{};
      for (final cat in categories) {
        categoryMap[cat.id] = cat.name;
      }
      
      return allServices.map((service) {
        return {
          'service': service,
          'categoryName': service.categoryId != null ? categoryMap[service.categoryId] ?? 'Unknown' : 'Root',
        };
      }).toList();
    } catch (e) {
      print('Error getting services with categories: $e');
      return [];
    }
  }

  // Refresh data for all tabs
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _serviceService.getCategories();
      final rootServices = await _serviceService.getRootServices();
      setState(() {
        _root.subcategories = categories;
        _root.services
          ..clear()
          ..addAll(rootServices);
        _isLoading = false;
      });
    } catch (e) {
      print('Error refreshing data: $e');
      setState(() => _isLoading = false);
    }
  }



  // Force refresh services data from database
  Future<void> _forceRefreshServicesData() async {
    try {
      // Force a rebuild by updating state
      setState(() {});
      // Also refresh the main data
      await _refreshData();
    } catch (e) {
      print('Error force refreshing services data: $e');
    }
  }

  // Tab 1: All (file-explorer view)
  Widget _buildAllTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final visibleCats = _current.subcategories
        .where((c) => _query.isEmpty || c.name.toLowerCase().contains(_query))
        .toList();
    List<ServiceItem> visibleServices = _current.services
        .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query))
        .toList();

    if (visibleCats.isEmpty && visibleServices.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.separated(
        itemCount: visibleCats.length + visibleServices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index < visibleCats.length) {
            final cat = visibleCats[index];
            return _FolderLikeCard(
              title: cat.name,
              subtitle: '${cat.subcategories.length} sub • ${cat.services.length} items',
              onTap: () => _selectCategoryChip(cat),
              onDelete: () => _deleteCategory(cat),
            );
          }
          final item = visibleServices[index - visibleCats.length];
          return _ServiceCard(
            item: item,
            onOpen: () => _openService(item),
            onDelete: () => _deleteService(item),
            onToggleEnabled: (v) async {
              setState(() => item.enabled = v);
              await _serviceService.toggleServiceStatus(item.id, v);
            },
            onMove: () => _showMoveServiceDialog(item),
          );
        },
      ),
    );
  }

  // Tab 2: Available Services
  Widget _buildAvailableServicesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllServicesWithCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final servicesWithCategories = snapshot.data ?? [];
        final availableServices = servicesWithCategories
            .where((item) {
              final service = item['service'] as ServiceItem;
              final query = _query.toLowerCase();
              return service.enabled && 
                     (query.isEmpty || service.name.toLowerCase().contains(query));
            })
            .toList();
        
        if (availableServices.isEmpty) {
          return const Center(child: Text('No available services'));
        }
        
        return RefreshIndicator(
          onRefresh: _forceRefreshServicesData,
          child: ListView.separated(
            itemCount: availableServices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = availableServices[index];
              final service = item['service'] as ServiceItem;
              final categoryName = item['categoryName'] as String;
              
              return _ServiceCardWithCategory(
                item: service,
                categoryName: categoryName,
                onOpen: () => _openService(service),
                onDelete: () => _deleteService(service),
                onToggleEnabled: (v) async {
                  setState(() => service.enabled = v);
                  await _serviceService.toggleServiceStatus(service.id, v);
                },
              );
            },
          ),
        );
      },
    );
  }

  // Tab 3: Unavailable Services
  Widget _buildUnavailableServicesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllServicesWithCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final servicesWithCategories = snapshot.data ?? [];
        final unavailableServices = servicesWithCategories
            .where((item) {
              final service = item['service'] as ServiceItem;
              final query = _query.toLowerCase();
              return !service.enabled && 
                     (query.isEmpty || service.name.toLowerCase().contains(query));
            })
            .toList();
        
        if (unavailableServices.isEmpty) {
          return RefreshIndicator(
            onRefresh: _forceRefreshServicesData,
            child: ListView(
              children: [
                const SizedBox(height: 100),
                const Center(child: Text('No unavailable services')),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Total services: ${servicesWithCategories.length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Query: "${_query}"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enabled services: ${servicesWithCategories.where((item) => (item['service'] as ServiceItem).enabled).length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Disabled services: ${servicesWithCategories.where((item) => !(item['service'] as ServiceItem).enabled).length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _forceRefreshServicesData,
          child: ListView.separated(
            itemCount: unavailableServices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = unavailableServices[index];
              final service = item['service'] as ServiceItem;
              final categoryName = item['categoryName'] as String;
              
              return _ServiceCardWithCategory(
                item: service,
                categoryName: categoryName,
                onOpen: () => _openService(service),
                onDelete: () => _deleteService(service),
                onToggleEnabled: (v) async {
                  setState(() => service.enabled = v);
                  await _serviceService.toggleServiceStatus(service.id, v);
                },
              );
            },
          ),
        );
      },
    );
  }


  Future<void> _deleteService(ServiceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Delete service "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final success = await _serviceService.deleteService(item.id);
        if (success) {
          setState(() {
            _current.services.removeWhere((s) => s.id == item.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete service'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(CategoryNode category) async {
    // Check if category has content
    final hasContent = category.subcategories.isNotEmpty || category.services.isNotEmpty;
    
    if (hasContent) {
      // Show options dialog for categories with content
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Category "${category.name}" contains:\n'
            '• ${category.subcategories.length} subcategories\n'
            '• ${category.services.length} services\n\n'
            'How would you like to proceed?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'move'),
              child: const Text('Move Services to Root'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'force'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Everything'),
            ),
          ],
        ),
      );

      if (choice == 'cancel') return;

      if (choice == 'move') {
        // Move services to root level
        try {
          final success = await _serviceService.moveServicesToRoot(category.id);
          if (success) {
            // Now delete the empty category
            final deleteSuccess = await _serviceService.deleteCategory(category.id);
            if (deleteSuccess) {
              setState(() {
                _current.subcategories.removeWhere((c) => c.id == category.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category deleted, services moved to root')),
              );
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (choice == 'force') {
        // Force delete everything
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Confirm Deletion'),
            content: Text(
              'This will PERMANENTLY DELETE:\n'
              '• Category "${category.name}"\n'
              '• All ${category.subcategories.length} subcategories\n'
              '• All ${category.services.length} services\n\n'
              'This action cannot be undone!'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        try {
          final success = await _serviceService.forceDeleteCategory(category.id);
          if (success) {
            setState(() {
              _current.subcategories.removeWhere((c) => c.id == category.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category and all contents deleted')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete category'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      // Empty category - safe to delete
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete empty category "${category.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        try {
          final success = await _serviceService.deleteCategory(category.id);
          if (success) {
            setState(() {
              _current.subcategories.removeWhere((c) => c.id == category.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category deleted successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete category'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show dialog to move a service to a different category
  Future<void> _showMoveServiceDialog(ServiceItem service) async {
    final categories = await _serviceService.getCategories();
    var currentCategory = categories.firstWhere(
      (cat) => cat.id == service.categoryId,
      orElse: () => CategoryNode(id: 'root', name: 'Root', subcategories: []),
    );

    final selectedCategory = await showDialog<CategoryNode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Move "${service.name}" to:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryNode>(
              value: currentCategory,
              items: [
                DropdownMenuItem(
                  value: CategoryNode(id: 'root', name: 'Root', subcategories: []),
                  child: const Text('Root (No Category)'),
                ),
                ...categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name),
                )),
              ],
              onChanged: (value) => currentCategory = value ?? currentCategory,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, currentCategory),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (selectedCategory != null) {
      await _moveService(service, selectedCategory);
    }
  }

  // Move service to a different category
  Future<void> _moveService(ServiceItem service, CategoryNode targetCategory) async {
    try {
      final newCategoryId = targetCategory.id == 'root' ? null : targetCategory.id;
      final success = await _serviceService.updateService(service.id, {
        'category_id': newCategoryId,
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service moved to ${targetCategory.name}'),
          ),
        );
        
        // Refresh the data to reflect changes
        await _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to move service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error moving service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Category name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        final newCategory = await _serviceService.createCategory(name, _current.id == 'root' ? null : _current.id);
        if (newCategory != null) {
          setState(() {
            _current.subcategories.add(newCategory);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addService() async {
    final ServiceItem? created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AddServicePage(
          categoryId: _current.id == 'root' ? null : _current.id,
        ),
        fullscreenDialog: true,
      ),
    );
    if (created != null) {
      setState(() => _current.services.add(created));
    }
  }

  void _openService(ServiceItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ServiceDetailsPage(item: item)),
    );
  }

  // Removed chip helpers

  void _selectCategoryChip(CategoryNode? node) {
    // node == null means select 'All'
    if (node == null) {
      setState(() => _stack.clear());
      return;
    }
    if (_stack.isEmpty) {
      setState(() => _stack.add(node));
      _loadServicesFor(node);
      return;
    }
    // Replace current with selected sibling
    setState(() {
      _stack.removeLast();
      _stack.add(node);
    });
    _loadServicesFor(node);
  }

  // Removed chip UI to keep file-explorer flow

  @override
  Widget build(BuildContext context) {
    final canPop = _stack.isNotEmpty;
    return WillPopScope(
      onWillPop: () async {
        if (_stack.isNotEmpty) {
          setState(() => _stack.removeLast());
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(canPop ? _current.name : 'Catalog'),
          leading: canPop
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _stack.removeLast()))
              : null,
          actions: const [],
          bottom: canPop ? null : TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Available'),
              Tab(text: 'Unavailable'),
            ],
            onTap: (index) {
              setState(() {});
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SearchBarMinis(
                hint: 'Search your catalog',
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              // Category chip row removed to restore file-explorer style
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: All (current file-explorer view)
                    _buildAllTab(),
                    // Tab 2: Available Services
                    _buildAvailableServicesTab(),
                    // Tab 3: Unavailable Services
                    _buildUnavailableServicesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _FabMenu(
          onAddCategory: _addCategory,
          onAddService: _addService,
        ),
      ),
    );
  }
}

// Old category tile retained for reference, not used after chip redesign

class _TrashIcon extends StatelessWidget {
  final Color? color;
  const _TrashIcon({this.color});

  @override
  Widget build(BuildContext context) {
    // Inline to avoid importing icons into widgets.dart consumers
    return SvgPicture.string(
      AppIcons.trashSvg,
      colorFilter: ColorFilter.mode(color ?? Colors.black87, BlendMode.srcIn),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final ServiceItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback? onMove;
  const _ServiceCard({required this.item, required this.onOpen, required this.onDelete, required this.onToggleEnabled, this.onMove});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black26, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Colors.black45),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('₹${widget.item.price}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Switch(
                  value: widget.item.enabled,
                  onChanged: (v) async {
                    widget.onToggleEnabled(v);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            if (widget.item.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.item.tags
                    .map((t) => Chip(label: Text(t), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                    .toList(),
              ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.description,
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(_expanded ? 'Show Less' : 'Show More', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (widget.item.media.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.item.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final m = widget.item.media[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MediaGalleryPage(items: widget.item.media))),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 96,
                          height: 72,
                          color: Colors.grey[200],
                          child: m.type == MediaType.image
                              ? (m.url.startsWith('http') || kIsWeb
                                  ? Image.network(m.url, fit: BoxFit.cover)
                                  : Image.file(File(m.url), fit: BoxFit.cover))
                              : const Icon(Icons.play_circle_fill, size: 32, color: Colors.black54),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Delete',
                  onPressed: widget.onDelete,
                  icon: const _TrashIcon(color: Colors.redAccent),
                ),
                if (widget.onMove != null) ...[
                  IconButton(
                    tooltip: 'Move Service',
                    onPressed: widget.onMove,
                    icon: const Icon(Icons.drag_handle, color: Colors.blue),
                  ),
                ],
                const Spacer(),
                TextButton(onPressed: widget.onOpen, child: const Text('Edit')),
                TextButton(
                  onPressed: () async {
                    final link = 'https://example.com/service/${widget.item.id}';
                    await Clipboard.setData(ClipboardData(text: link));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
                    }
                  },
                  child: const Text('Share'),
                ),
                FilledButton.tonal(onPressed: widget.onOpen, child: const Text('Open')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ServiceCardWithCategory extends StatelessWidget {
  final ServiceItem item;
  final String categoryName;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;
  
  const _ServiceCardWithCategory({
    required this.item,
    required this.categoryName,
    required this.onOpen,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black26, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Colors.black45),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: item.enabled,
                  onChanged: onToggleEnabled,
                )
              ],
            ),
            const SizedBox(height: 8),
            if (item.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.tags
                    .map((t) => Chip(label: Text(t), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                    .toList(),
              ),
            const SizedBox(height: 8),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const _TrashIcon(color: Colors.redAccent),
                ),
                const Spacer(),
                TextButton(onPressed: onOpen, child: const Text('Edit')),
                FilledButton.tonal(onPressed: onOpen, child: const Text('Open')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _FabMenu extends StatefulWidget {
  final VoidCallback onAddCategory;
  final VoidCallback onAddService;
  const _FabMenu({required this.onAddCategory, required this.onAddService});

  @override
  State<_FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<_FabMenu> with SingleTickerProviderStateMixin {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open) ...[
          FloatingActionButton.extended(
            heroTag: 'fab_cat',
            onPressed: () {
              setState(() => _open = false);
              widget.onAddCategory();
            },
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Add Category'),
            foregroundColor: Colors.white,
            backgroundColor: primary,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'fab_svc',
            onPressed: () {
              setState(() => _open = false);
              widget.onAddService();
            },
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Add Service'),
            foregroundColor: Colors.white,
            backgroundColor: primary,
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: () => setState(() => _open = !_open),
          child: Icon(_open ? Icons.close : Icons.add),
        )
      ],
    );
  }
}

class ServiceDetailsPage extends StatelessWidget {
  final ServiceItem item;
  const ServiceDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.media.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: item.media.length,
                  controller: PageController(viewportFraction: 0.9),
                  itemBuilder: (context, i) {
                    final m = item.media[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.grey[200],
                          child: m.type == MediaType.image
                              ? (m.url.startsWith('http') || kIsWeb
                                  ? Image.network(m.url, fit: BoxFit.cover)
                                  : Image.file(File(m.url), fit: BoxFit.cover))
                              : const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.black54)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text('₹${item.price}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Status: ${item.enabled ? 'Enabled' : 'Disabled'}', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (item.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.tags.map((t) => Chip(label: Text(t))).toList(),
              ),
            const SizedBox(height: 12),
            Text(item.description),
          ],
        ),
      ),
    );
  }
}

class MediaGalleryPage extends StatelessWidget {
  final List<MediaItem> items;
  const MediaGalleryPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final m = items[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.grey[200],
              child: m.type == MediaType.image
                  ? (m.url.startsWith('http') || kIsWeb
                      ? Image.network(m.url, fit: BoxFit.cover)
                      : Image.file(File(m.url), fit: BoxFit.cover))
                  : const Center(child: Icon(Icons.play_circle_fill, size: 36, color: Colors.black54)),
            ),
          );
        },
      ),
    );
  }
}

class _FolderLikeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;
  final bool isDraggable;
  const _FolderLikeCard({
    required this.title, 
    required this.subtitle, 
    required this.onTap, 
    this.onDelete, 
    this.onMove,
    this.isDraggable = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black26, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder, color: Colors.black45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                IconButton(
                  tooltip: 'Delete Category',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
                const SizedBox(width: 8),
              ],
              if (onMove != null) ...[
                IconButton(
                  tooltip: 'Move Category',
                  onPressed: onMove,
                  icon: const Icon(Icons.drag_handle, color: Colors.blue),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right)
            ],
          ),
        ),
      ),
    );

    if (isDraggable) {
      return Draggable<CategoryNode>(
        data: CategoryNode(id: title, name: title, subcategories: []), // We'll pass the actual category data
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: cardContent,
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class _AddServicePage extends StatefulWidget {
  final String? categoryId;

  const _AddServicePage({
    this.categoryId,
  });

  @override
  State<_AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<_AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final List<String> _tags = <String>[];
  final List<MediaItem> _media = <MediaItem>[];
  bool _enabled = true;
  bool _isSaving = false;

  void _addTagFromInput() {
    final raw = _tagCtrl.text.trim();
    if (raw.isEmpty) return;
    for (final part in raw.split(',')) {
      final tag = part.trim();
      if (tag.isNotEmpty && !_tags.contains(tag)) {
        _tags.add(tag);
      }
    }
    _tagCtrl.clear();
    setState(() {});
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        for (final f in files) {
          _media.add(MediaItem(url: f.path, type: MediaType.image));
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final f = await picker.pickVideo(source: ImageSource.gallery);
    if (f != null) {
      setState(() => _media.add(MediaItem(url: f.path, type: MediaType.video)));
    }
  }

  Future<void> _addMediaUrl() async {
    final urlCtrl = TextEditingController();
    MediaType selected = MediaType.image;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add media from URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
            const SizedBox(height: 8),
            DropdownButtonFormField<MediaType>(
              value: selected,
              items: const [
                DropdownMenuItem(value: MediaType.image, child: Text('Image')),
                DropdownMenuItem(value: MediaType.video, child: Text('Video')),
              ],
              onChanged: (v) => selected = v ?? MediaType.image,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && urlCtrl.text.trim().isNotEmpty) {
      setState(() => _media.add(MediaItem(url: urlCtrl.text.trim(), type: selected)));
    }
  }

  void _removeMediaAt(int index) {
    setState(() => _media.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert media to URLs (for now, just use the paths as URLs)
      final mediaUrls = _media.map((m) => m.url).toList();

      final service = await ServiceService().createService(
        name: _nameCtrl.text.trim(),
        categoryId: widget.categoryId, // allow null for root services
        price: double.parse(_priceCtrl.text),
        tags: List<String>.from(_tags),
        description: _descCtrl.text.trim(),
        mediaUrls: mediaUrls,
      );

      if (service != null) {
        // Navigate back with the created service
        Navigator.pop(context, service);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter number' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Enabled'),
                  const SizedBox(width: 8),
                  Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              const Text('Tags'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._tags.map(
                    (t) => Chip(
                      label: Text(t),
                      onDeleted: () => setState(() => _tags.remove(t)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _tagCtrl,
                      decoration: const InputDecoration(hintText: 'Add tag'),
                      onSubmitted: (_) => _addTagFromInput(),
                      onChanged: (v) {
                        if (v.contains(',')) _addTagFromInput();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(onPressed: _pickImages, icon: const Icon(Icons.image), label: const Text('Add Images')),
                  const SizedBox(width: 8),
                  FilledButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.videocam), label: const Text('Add Video')),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(onPressed: _addMediaUrl, icon: const Icon(Icons.link), label: const Text('Add via URL')),
              const SizedBox(height: 12),
              if (_media.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _media.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, i) {
                    final m = _media[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.grey[200],
                            child: m.type == MediaType.image
                                ? (m.url.startsWith('http') || kIsWeb
                                    ? Image.network(m.url, fit: BoxFit.cover)
                                    : Image.file(File(m.url), fit: BoxFit.cover))
                                : const Center(child: Icon(Icons.play_circle_fill, size: 36, color: Colors.black54)),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkResponse(
                            onTap: () => _removeMediaAt(i),
                            radius: 18,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

