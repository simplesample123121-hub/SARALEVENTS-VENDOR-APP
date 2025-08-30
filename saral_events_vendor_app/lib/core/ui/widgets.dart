import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';

class SearchBarMinis extends StatelessWidget {
  final String hint;
  final VoidCallback? onFilter;
  const SearchBarMinis({super.key, this.hint = 'Search services, bookings...', this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
                             prefixIcon: SizedBox(
                 width: 8,
                 height: 8,
                 child: Center(
                   child: SvgPicture.string(
                     AppIcons.searchSvg,
                     width: 25,
                     height: 25,
                     colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                   ),
                 ),
               ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onFilter,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            child: const SvgIcon(AppIcons.filterSvg, size: 18, color: Colors.white),
          ),
        )
      ],
    );
  }
}

class ServiceTileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback? onTap;
  const ServiceTileCard({super.key, required this.title, required this.subtitle, required this.price, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
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
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip({super.key, required this.label});

  Color _colorFor(String l) {
    switch (l.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFE8D6);
      case 'confirmed':
        return const Color(0xFFD1FAE5);
      case 'completed':
        return const Color(0xFFDBEAFE);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _textFor(String l) {
    switch (l.toLowerCase()) {
      case 'pending':
        return const Color(0xFFB45309);
      case 'confirmed':
        return const Color(0xFF065F46);
      case 'completed':
        return const Color(0xFF1D4ED8);
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _colorFor(label), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: _textFor(label), fontWeight: FontWeight.w600)),
    );
  }
}


