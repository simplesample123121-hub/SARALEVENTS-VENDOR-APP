import 'package:flutter/material.dart';
import 'checkout_state.dart';

class InstallmentCard extends StatelessWidget {
  final List<double> installments; // length 3
  final double total;
  final EdgeInsetsGeometry? margin;

  const InstallmentCard({
    super.key,
    required this.installments,
    required this.total,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final noteStyle = textTheme.bodySmall?.copyWith(color: Colors.red.shade700);
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, color: Colors.red),
              const SizedBox(width: 8),
              Text('Installment Breakdown', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Total: ₹${total.toStringAsFixed(0)}', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _row('Today', installments[0]),
          const SizedBox(height: 6),
          _row('+30 days', installments[1]),
          const SizedBox(height: 6),
          _row('+60 days', installments[2]),
          const SizedBox(height: 12),
          Text('Note: Pay in 3 easy installments. Late fees may apply.', style: noteStyle),
        ],
      ),
    );
  }

  Widget _row(String label, double amount) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class BillingForm extends StatefulWidget {
  final BillingDetails? initial;
  final void Function(BillingDetails) onSave;

  const BillingForm({super.key, this.initial, required this.onSave});

  @override
  State<BillingForm> createState() => _BillingFormState();
}

class _BillingFormState extends State<BillingForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  DateTime? _eventDate;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i.name;
      _email.text = i.email;
      _phone.text = i.phone;
      _message.text = i.messageToVendor ?? '';
      _eventDate = i.eventDate;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _field(_name, 'Full Name', TextInputType.name),
          const SizedBox(height: 12),
          _field(_email, 'Email', TextInputType.emailAddress, validator: _validateEmail),
          const SizedBox(height: 12),
          _field(_phone, 'Phone', TextInputType.phone),
          const SizedBox(height: 12),
          _dateField(context),
          const SizedBox(height: 12),
          _field(_message, 'Message to vendor (optional)', TextInputType.multiline, maxLines: 3, required: false),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDBB42),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(BillingDetails(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        eventDate: _eventDate,
        messageToVendor: _message.text.trim().isEmpty ? null : _message.text.trim(),
      ));
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return ok ? null : 'Enter valid email';
  }

  Widget _dateField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: _eventDate ?? now.add(const Duration(days: 7)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 365 * 2)),
        );
        if (d != null) setState(() => _eventDate = d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Event date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(16),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _eventDate == null
                ? 'Select event date'
                : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, TextInputType type,
      {FormFieldValidator<String>? validator, int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return '$label required';
        return validator != null ? validator(v) : null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

class PaymentMethodSelector extends StatefulWidget {
  final SelectedPaymentMethod? initial;
  final void Function(SelectedPaymentMethod) onChanged;

  const PaymentMethodSelector({super.key, this.initial, required this.onChanged});

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethodType _type = PaymentMethodType.cash;
  final _upi = TextEditingController();
  final _cardNumber = TextEditingController();
  final _cardName = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();
  String? _bankName;

  final _banks = const [
    'HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak', 'Yes Bank', 'IDFC First',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _type = i.type;
      _upi.text = i.upiId ?? '';
      _cardNumber.text = i.cardNumber ?? '';
      _cardName.text = i.cardName ?? '';
      _cardExpiry.text = i.cardExpiry ?? '';
      _cardCvv.text = i.cardCvv ?? '';
      _bankName = i.bankName;
    }
  }

  @override
  void dispose() {
    _upi.dispose();
    _cardNumber.dispose();
    _cardName.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _radioTile('Pay with Cash', PaymentMethodType.cash),
        _radioTile('UPI', PaymentMethodType.upi,
            child: _type == PaymentMethodType.upi ? _upiField() : null),
        _radioTile('Credit / Debit Card', PaymentMethodType.card,
            child: _type == PaymentMethodType.card ? _cardFields() : null),
        _radioTile('Net Banking', PaymentMethodType.netBanking,
            child: _type == PaymentMethodType.netBanking ? _netBankingFields() : null),
      ],
    );
  }

  Widget _radioTile(String label, PaymentMethodType value, {Widget? child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          RadioListTile<PaymentMethodType>(
            value: value,
            groupValue: _type,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _type = v);
              widget.onChanged(_current());
            },
            title: Text(label),
          ),
          if (child != null) Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  Widget _upiField() {
    return TextField(
      controller: _upi,
      decoration: const InputDecoration(labelText: 'UPI ID', border: OutlineInputBorder()),
      onChanged: (_) => widget.onChanged(_current()),
    );
  }

  Widget _cardFields() {
    return Column(
      children: [
        TextField(controller: _cardNumber, decoration: const InputDecoration(labelText: 'Card Number', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _cardName, decoration: const InputDecoration(labelText: 'Name on Card', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _cardExpiry, decoration: const InputDecoration(labelText: 'Expiry (MM/YY)', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _cardCvv, decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()))),
        ]),
      ],
    );
  }

  Widget _netBankingFields() {
    return DropdownButtonFormField<String>(
      value: _bankName,
      items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
      onChanged: (v) {
        setState(() => _bankName = v);
        widget.onChanged(_current());
      },
      decoration: const InputDecoration(labelText: 'Select Bank', border: OutlineInputBorder()),
    );
  }

  SelectedPaymentMethod _current() {
    return SelectedPaymentMethod(
      type: _type,
      upiId: _upi.text.trim().isEmpty ? null : _upi.text.trim(),
      cardNumber: _cardNumber.text.trim().isEmpty ? null : _cardNumber.text.trim(),
      cardName: _cardName.text.trim().isEmpty ? null : _cardName.text.trim(),
      cardExpiry: _cardExpiry.text.trim().isEmpty ? null : _cardExpiry.text.trim(),
      cardCvv: _cardCvv.text.trim().isEmpty ? null : _cardCvv.text.trim(),
      bankName: _bankName,
    );
  }
}


