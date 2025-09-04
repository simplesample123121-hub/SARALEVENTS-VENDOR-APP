import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserCatalogScreen extends StatefulWidget {
  const UserCatalogScreen({super.key});

  @override
  State<UserCatalogScreen> createState() => _UserCatalogScreenState();
}

class _UserCatalogScreenState extends State<UserCatalogScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _loading = true;
  String _query = '';
  List<Map<String, dynamic>> _services = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  String? _selectedCategoryId; // null => All

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final services = await _supabase
          .from('services')
          .select('id,name,price,description,media_urls,category_id')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Fetch top-level categories across all vendors (parent_id is null)
      final categories = await _supabase
          .from('categories')
          .select('id,name,parent_id')
          .filter('parent_id', 'is', null)
          .order('name');
      setState(() {
        _services = List<Map<String, dynamic>>.from(services);
        _categories = List<Map<String, dynamic>>.from(categories);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _services.where((s) {
      if (_query.isEmpty) return true;
      final name = (s['name'] as String?)?.toLowerCase() ?? '';
      return name.contains(_query);
    }).where((s) {
      if (_selectedCategoryId == null) return true; // All
      return s['category_id'] == _selectedCategoryId;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Search services'),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            // Category filter row
            if (_categories.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c['name'] ?? ''),
                            selected: _selectedCategoryId == c['id'],
                            onSelected: (_) => setState(() => _selectedCategoryId = c['id'] as String),
                          ),
                        )),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text('No services'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            final media = (s['media_urls'] as List?) ?? const [];
                            return Card(
                              elevation: 2,
                              child: ListTile(
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: media.isEmpty
                                      ? const Icon(Icons.image)
                                      : const Icon(Icons.image),
                                ),
                                title: Text(s['name'] ?? ''),
                                subtitle: Text((s['description'] ?? '').toString(),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: Text('₹${(s['price'] ?? 0).toString()}'),
                                onTap: () {},
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


