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

class _ServicesScreenState extends State<ServicesScreen> {
  late final CategoryNode _root;
  final List<CategoryNode> _stack = <CategoryNode>[];
  final ServiceService _serviceService = ServiceService();
  bool _isLoading = false;

  CategoryNode get _current => _stack.isEmpty ? _root : _stack.last;

  @override
  void initState() {
    super.initState();
    _root = CategoryNode(id: 'root', name: 'All', subcategories: []);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _serviceService.getCategories();
      setState(() {
        _root.subcategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateInto(CategoryNode node) {
    setState(() => _stack.add(node));
  }

  Future<void> _deleteCategory(CategoryNode cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}" and all its contents?'),
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
        final success = await _serviceService.deleteCategory(cat.id);
        if (success) {
          setState(() {
            _current.subcategories.removeWhere((c) => c.id == cat.id);
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
          onServiceCreated: (service) {
            setState(() => _current.services.add(service));
          },
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SearchBarMinis(hint: 'Search your catalog'),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.separated(
                      itemCount: _current.subcategories.length + _current.services.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index < _current.subcategories.length) {
                          final cat = _current.subcategories[index];
                          return _CategoryTile(
                            name: cat.name,
                            onTap: () => _navigateInto(cat),
                            onDelete: () => _deleteCategory(cat),
                          );
                        }
                        final item = _current.services[index - _current.subcategories.length];
                        return _ServiceCard(
                          item: item,
                          onOpen: () => _openService(item),
                          onDelete: () => _deleteService(item),
                        );
                      },
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

class _CategoryTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _CategoryTile({required this.name, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black26, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            constraints: const BoxConstraints(minHeight: 72),
            child: Center(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: InkResponse(
              onTap: onDelete,
              radius: 20,
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: _TrashIcon(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  const _ServiceCard({required this.item, required this.onOpen, required this.onDelete});

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
                  onChanged: (v) => setState(() => widget.item.enabled = v),
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

class _AddServicePage extends StatefulWidget {
  final String? categoryId;
  final Function(ServiceItem)? onServiceCreated;

  const _AddServicePage({
    this.categoryId,
    this.onServiceCreated,
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
        categoryId: widget.categoryId ?? 'root',
        price: double.parse(_priceCtrl.text),
        tags: List<String>.from(_tags),
        description: _descCtrl.text.trim(),
        mediaUrls: mediaUrls,
      );

      if (service != null) {
        // Call the callback if provided
        widget.onServiceCreated?.call(service);
        
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

