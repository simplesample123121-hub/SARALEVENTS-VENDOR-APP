import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_models.dart';
import '../services/service_service.dart';
import 'booking_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceItem service;
  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late final ServiceService _serviceService;
  DateTime _weekStart = DateTime.now();
  DateTime? _selectedDay;
  List<ServiceItem> _similar = <ServiceItem>[];

  @override
  void initState() {
    super.initState();
    _serviceService = ServiceService(Supabase.instance.client);
    _selectedDay = DateTime.now();
    _loadSimilar();
  }

  Future<void> _loadSimilar() async {
    try {
      final all = await _serviceService.getAllServices();
      setState(() {
        _similar = all
            .where((s) => s.id != widget.service.id && s.vendorName != widget.service.vendorName)
            .take(6)
            .toList();
      });
    } catch (_) {}
  }

  List<DateTime> _currentWeek() {
    final start = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    return List<DateTime>.generate(7, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final imageUrl = svc.media.isNotEmpty ? svc.media.first.url : null;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)),
            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border))],
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? CachedNetworkImage(imageUrl: Uri.encodeFull(imageUrl), fit: BoxFit.cover)
                  : Container(color: Colors.black12),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          svc.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.store, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(svc.vendorName, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: const [Icon(Icons.location_on, size: 16, color: Colors.grey), SizedBox(width: 4), Text('Telangana , Hyderabad. 2.4km', style: TextStyle(color: Colors.grey))]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      (svc.ratingAvg != null && svc.ratingCount != null)
                          ? '${svc.ratingAvg!.toStringAsFixed(1)} rating  •  ${svc.ratingCount} reviews'
                          : 'No ratings yet',
                      style: const TextStyle(color: Colors.grey),
                    )
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.group, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      (svc.capacityMin != null && svc.capacityMax != null)
                          ? '${svc.capacityMin}-${svc.capacityMax} Guests'
                          : 'Capacity: N/A',
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.local_parking, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      (svc.parkingSpaces != null)
                          ? '${svc.parkingSpaces}+ Car parking'
                          : 'Parking: N/A',
                    )
                  ]),
                  const SizedBox(height: 12),
                  if (svc.suitedFor.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: svc.suitedFor.map((e) => _Chip(e)).toList(),
                    ),
                  const SizedBox(height: 16),
                  _weekSelector(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(service: svc)));
                      },
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF4B63E), foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Check Availability Dates', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Similar Options', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _similar.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _SimilarCard(item: _similar[i]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('People also brought this with..', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _SmallCategory(icon: Icons.photo_camera_outlined, label: 'Photography'),
                      _SmallCategory(icon: Icons.deck_outlined, label: 'Decoration'),
                      _SmallCategory(icon: Icons.restaurant, label: 'Catering'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Center(child: Text('Other Services & details', style: TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(height: 8),
                  if (svc.policies.isNotEmpty) _bullets(svc.policies),
                  const SizedBox(height: 8),
                  if (svc.features.isNotEmpty)
                    _numbered(svc.features.entries.map((e) => '${e.key}: ${e.value}').toList()),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Center(child: Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(height: 8),
                  _reviewSummary(),
                  const SizedBox(height: 8),
                  _reviewTile('Aysha Mishra', '12/04/25 • 11:07 AM', 'Quite big, Sufficient parking space good atmosphere, Loved the Place for party.'),
                  _reviewTile('Rajul Jayakrya', '12/04/24 • 05:20 AM', 'Great Location, Our family enjoyed it and good service.'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _weekSelector() {
    final days = _currentWeek();
    return Row(
      children: [
        IconButton(onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))), icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((d) {
              final selected = _selectedDay?.day == d.day && _selectedDay?.month == d.month && _selectedDay?.year == d.year;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = d),
                child: Column(
                  children: [
                    Text(['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][d.weekday % 7], style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: selected ? const Color(0xFF4CAF50) : Colors.black12,
                      child: Text('${d.day}', style: TextStyle(color: selected ? Colors.white : Colors.black87)),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        IconButton(onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))), icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _bullets(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(t))]),
              ))
          .toList(),
    );
  }

  Widget _numbered(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${i + 1}. '), Expanded(child: Text(lines[i]))]),
          )),
    );
  }

  Widget _reviewSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Column(children: const [Text('5.5k', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), SizedBox(height: 4), Icon(Icons.star, color: Colors.amber)]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(height: 8, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
                  )),
            ),
          )
        ],
      ),
    );
  }

  Widget _reviewTile(String name, String date, String text) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 6), Text(text)]),
      trailing: const Icon(Icons.more_horiz),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black12.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _SmallCategory extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SmallCategory({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.black12.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 28)), const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.grey))]);
  }
}

class _SimilarCard extends StatelessWidget {
  final ServiceItem item;
  const _SimilarCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.media.isNotEmpty ? item.media.first.url : null;
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ServiceDetailsScreen(service: item)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: imageUrl != null
                      ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.black12.withOpacity(0.06)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Capacity 300-400 Guest / With Catering', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹ ${item.price.toStringAsFixed(0)}/-', style: const TextStyle(fontWeight: FontWeight.w800)),
                        Row(children: const [Icon(Icons.star, size: 14, color: Color(0xFFFFC107)), SizedBox(width: 4), Text('4.5k')]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(service: item)));
                        },
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
