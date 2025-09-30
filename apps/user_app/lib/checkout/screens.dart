import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_state.dart';
import 'widgets.dart';
import '../services/razorpay_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shared button style
ButtonStyle _primaryBtn(BuildContext context) => ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFFDBB42),
  foregroundColor: Colors.black87,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

class CartPage extends StatelessWidget {
  final VoidCallback onNext;
  const CartPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckoutState>();
    final items = state.items;
    final installments = state.installmentBreakdown;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          InstallmentCard(installments: installments, total: state.totalPrice),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) => _cartTile(context, items[i]),
            ),
          ),
          _userDetailsSummary(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: ElevatedButton(onPressed: onNext, style: _primaryBtn(context), child: const Text('Next')),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _cartTile(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        title: Text(item.title),
        subtitle: Text(item.subtitle ?? item.category),
        trailing: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _userDetailsSummary() {
    return Consumer<CheckoutState>(builder: (context, state, _) {
      final details = state.billingDetails;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                details == null
                    ? 'No billing details yet'
                    : '${details.name} • ${details.phone}\n${details.email}',
              ),
            ),
            Text('Total: ₹${state.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    });
  }

  Widget _bottomNav() { return const SizedBox.shrink(); }
}

class PaymentDetailsPage extends StatelessWidget {
  final VoidCallback onChoosePayment;
  final VoidCallback onNext;
  const PaymentDetailsPage({super.key, required this.onChoosePayment, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckoutState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InstallmentCard(installments: state.installmentBreakdown, total: state.totalPrice),
          const SizedBox(height: 8),
          BillingForm(
            initial: state.billingDetails,
            onSave: (d) {
              context.read<CheckoutState>().saveBillingDetails(d);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details saved')));
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onChoosePayment,
                  style: _primaryBtn(context),
                  child: const Text('Choose Payment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onNext, child: const Text('Next')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentSummaryPage extends StatelessWidget {
  final VoidCallback onNext;
  const PaymentSummaryPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckoutState>();
    final d = state.billingDetails;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Billing Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (d == null) const Text('No details saved') else ...[
                  Text('Name: ${d.name}') ,
                  Text('Email: ${d.email}') ,
                  Text('Phone: ${d.phone}') ,
                  if (d.eventDate != null) Text('Event: ${d.eventDate!.day}/${d.eventDate!.month}/${d.eventDate!.year}') ,
                  if (d.messageToVendor != null) Text('Message: ${d.messageToVendor}') ,
                ],
                const SizedBox(height: 12),
                InstallmentCard(installments: state.installmentBreakdown, total: state.totalPrice, margin: EdgeInsets.zero),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: onNext, style: _primaryBtn(context), child: const Text('Next'))),
          ]),
        ],
      ),
    );
  }
}

class PaymentMethodPage extends StatefulWidget {
  final VoidCallback onNext;
  const PaymentMethodPage({super.key, required this.onNext});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  SelectedPaymentMethod? _method;
  final RazorpayService _razorpay = RazorpayService();

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckoutState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InstallmentCard(installments: state.installmentBreakdown, total: state.totalPrice),
          PaymentMethodSelector(
            initial: state.paymentMethod,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final state = context.read<CheckoutState>();
                  final m = _method ?? SelectedPaymentMethod(type: PaymentMethodType.cash);
                  state.savePaymentMethod(m);

                  if (m.type == PaymentMethodType.cash) {
                    widget.onNext();
                    return;
                  }

                  // Prepare user details
                  final user = Supabase.instance.client.auth.currentUser;
                  final name = state.billingDetails?.name ?? user?.userMetadata?['name'] ?? 'Customer';
                  final email = state.billingDetails?.email ?? user?.email ?? '';
                  final phone = state.billingDetails?.phone ?? '';

                  // Create order via Edge Function
                  try {
                    final amountPaise = (state.totalPrice * 100).round();
                    final order = await _razorpay.createOrderOnServer(
                      amountInPaise: amountPaise,
                      currency: 'INR',
                      receipt: 'ord_${DateTime.now().millisecondsSinceEpoch}',
                      notes: {
                        'app': 'saral_user',
                      },
                    );

                    // Get RZP key id from env (via Supabase functions config or remote config)
                    final keyId = Supabase.instance.client.functions.invoke('config_get', body: {'key': 'RAZORPAY_KEY_ID'});
                    final res = await keyId;
                    final key = (res.status == 200 && res.data is Map && res.data['value'] is String)
                        ? res.data['value'] as String
                        : '';
                    if (key.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Razorpay Key ID missing')));
                      return;
                    }

                    _razorpay.init(
                      onSuccess: (paymentId) {
                        widget.onNext();
                      },
                      onError: (code, message) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $message')));
                      },
                    );

                    _razorpay.openCheckout(
                      keyId: key,
                      amountInPaise: amountPaise,
                      name: 'Saral Events',
                      description: 'Service payment',
                      orderId: order['id'] as String,
                      currency: 'INR',
                      prefillName: name,
                      prefillEmail: email,
                      prefillContact: phone,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: _primaryBtn(context),
                child: const Text('Next'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}


