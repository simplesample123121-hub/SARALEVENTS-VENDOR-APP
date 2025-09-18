import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RazorpayService {
  Razorpay? _razorpay;
  void Function(String paymentId)? onSuccess;
  void Function(String code, String message)? onError;
  void Function()? onExternalWallet;

  bool get isInitialized => _razorpay != null;

  void init({
    required void Function(String paymentId) onSuccess,
    required void Function(String code, String message) onError,
    void Function()? onExternalWallet,
  }) {
    dispose();
    _razorpay = Razorpay();
    this.onSuccess = onSuccess;
    this.onError = onError;
    this.onExternalWallet = onExternalWallet;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  Future<Map<String, dynamic>> createOrderOnServer({
    required int amountInPaise,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    // This calls a Supabase Edge Function 'create_razorpay_order'
    // which securely uses your Razorpay key_secret to create an order
    final client = Supabase.instance.client;
    final res = await client.functions.invoke(
      'create_razorpay_order',
      body: jsonEncode({
        'amount': amountInPaise,
        'currency': currency,
        'receipt': receipt,
        'notes': notes ?? {},
      }),
    );
    if (res.status != 200) {
      throw Exception('Failed to create order: ${res.data}');
    }
    return res.data as Map<String, dynamic>;
  }

  void openCheckout({
    required String keyId,
    required int amountInPaise,
    required String name,
    required String description,
    required String orderId,
    String currency = 'INR',
    String? prefillName,
    String? prefillEmail,
    String? prefillContact,
    Map<String, dynamic>? notes,
  }) {
    if (_razorpay == null) {
      throw StateError('Razorpay not initialized');
    }
    final options = {
      'key': keyId,
      'amount': amountInPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        if (prefillName != null) 'name': prefillName,
        if (prefillEmail != null) 'email': prefillEmail,
        if (prefillContact != null) 'contact': prefillContact,
      },
      'notes': notes ?? {},
      'theme': {'color': '#FDBB42'},
    };
    if (kDebugMode) debugPrint('Opening Razorpay with: $options');
    _razorpay!.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError?.call('${response.code}', response.message ?? 'Unknown error');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call();
  }
}


