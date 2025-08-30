import 'package:flutter/material.dart';
import '../../core/ui/widgets.dart';
import '../../core/ui/app_icons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Store'),
        actions: [
          IconButton(onPressed: () {}, icon: SvgIcon(AppIcons.bellSvg, size: 22)),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchBarMinis(hint: 'Search bookings, services...'),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _StatCard(title: 'Earnings', value: '₹0')),
                SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Bookings', value: '0')),
              ],
            ),
            const SizedBox(height: 12),
            const _StatCard(title: 'Services', value: '0'),
            const SizedBox(height: 24),
            Text('Recent Bookings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: SvgIcon(AppIcons.calendarSvg, size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('No bookings yet'),
                  subtitle: const Text('Bookings will appear here'),
                  trailing: const StatusChip(label: 'Pending'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


