import 'package:flutter/material.dart';
import '../services/service_models.dart';
import '../../core/ui/widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = List.generate(
      8,
      (i) => Booking(
        id: 'bk_$i',
        serviceId: 'svc_$i',
        status: i % 3 == 0 ? 'Pending' : i % 3 == 1 ? 'Confirmed' : 'Completed',
        date: DateTime.now().subtract(Duration(days: i)),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final b = bookings[index];
          return Card(
            child: ListTile(
              title: Text('Booking ${b.id}'),
              subtitle: Text(b.date.toLocal().toString().split(' ').first),
              leading: const Icon(Icons.receipt_long, size: 22),
              trailing: StatusChip(label: b.status),
            ),
          );
        },
      ),
    );
  }
}


