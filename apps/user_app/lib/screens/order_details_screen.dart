import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_repository.dart';
import '../core/utils/time_utils.dart';
import '../services/receipt_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderRepository _repo;
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;
  final ReceiptService _receiptService = ReceiptService();

  @override
  void initState() {
    super.initState();
    _repo = OrderRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.getOrderById(widget.orderId);
      setState(() {
        _order = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (_order != null)
            IconButton(
              tooltip: 'Share receipt',
              icon: const Icon(Icons.ios_share),
              onPressed: () {
                final o = _order!;
                _receiptService.shareReceipt(context, o);
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final o = _order!;
    final status = (o['status'] as String? ?? 'pending').toUpperCase();
    final total = (o['total_amount'] as num? ?? 0).toDouble();
    final itemsJson = o['items_json'] as dynamic;
    final List items = itemsJson is String ? jsonDecode(itemsJson) : (itemsJson ?? []);
    final billingName = o['billing_name'] as String?;
    final billingEmail = o['billing_email'] as String?;
    final billingPhone = o['billing_phone'] as String?;
    final gateway = o['gateway'] as String?;
    final gatewayOrderId = o['gateway_order_id'] as String?;
    final paymentId = o['payment_id'] as String?;
    final createdAt = o['created_at'] as String?;
    final createdPretty = TimeUtils.formatDateTime(createdAt);
    final rel = TimeUtils.relativeTime(createdAt);
    // derive simple 3-part installment breakdown from total
    final installments = [0.34, 0.33, 0.33].map((p) => total * p).toList(growable: false);
    final orderId = (o['id'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Row(
            children: [
              const Icon(Icons.receipt_long),
              const SizedBox(width: 12),
              Expanded(child: Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Billing', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (billingName != null) Text(billingName),
              if (billingEmail != null) Text(billingEmail),
              if (billingPhone != null) Text(billingPhone),
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text('Created: $createdPretty (${rel.isEmpty ? '' : rel})', style: TextStyle(color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (items.isEmpty) const Text('No item details') else ...[
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('${it['title'] ?? it['item_id'] ?? 'Item'}')),
                        Text('₹${((it['price'] as num?) ?? 0).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Gateway: ${gateway ?? '-'}'),
              _copyRow(context, 'App Order ID', orderId),
              _copyRow(context, 'Gateway Order', gatewayOrderId ?? '-'),
              _copyRow(context, 'Payment ID', paymentId ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Installments (example)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _rowLabelValue('Today', '₹${installments[0].toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _rowLabelValue('+30 days', '₹${installments[1].toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _rowLabelValue('+60 days', '₹${installments[2].toStringAsFixed(2)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _copyRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(child: Text('$label: $value')),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: value == '-' || value.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                },
        ),
      ],
    );
  }

  Widget _rowLabelValue(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}


