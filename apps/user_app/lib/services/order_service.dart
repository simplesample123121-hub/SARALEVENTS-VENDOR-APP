import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../checkout/checkout_state.dart';

class OrderService {
  final SupabaseClient _supabase;

  OrderService(this._supabase);

  /// Create an application-level order with status 'pending'
  /// Returns the created order id (string/uuid) or throws
  Future<String> createPendingOrder({
    required CheckoutState checkout,
    Map<String, dynamic>? extra,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final billing = checkout.billingDetails;
    if (billing == null) {
      throw StateError('Billing details missing');
    }

    final total = checkout.totalPrice;
    final items = checkout.items
        .map((e) => {
              'item_id': e.id,
              'title': e.title,
              'category': e.category,
              'price': e.price,
              if (e.subtitle != null) 'subtitle': e.subtitle,
            })
        .toList();

    final insert = {
      'user_id': user.id,
      'status': 'pending',
      'total_amount': total,
      'billing_name': billing.name,
      'billing_email': billing.email,
      'billing_phone': billing.phone,
      'event_date': billing.eventDate?.toIso8601String(),
      'message_to_vendor': billing.messageToVendor,
      'items_json': jsonEncode(items),
      if (extra != null) 'meta': jsonEncode(extra),
    };

    final res = await _supabase.from('orders').insert(insert).select('id').single();
    final orderId = res['id'].toString();

    // Optionally insert order_items rows if your schema has a separate table
    try {
      await _supabase.from('order_items').insert(
        checkout.items.map((e) => {
              'order_id': orderId,
              'item_id': e.id,
              'title': e.title,
              'category': e.category,
              'price': e.price,
            }),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('order_items insert skipped/failed: $e');
      }
    }

    return orderId;
  }

  /// Attach Razorpay order id and amount (paise) to our order
  Future<void> attachRazorpayOrder({
    required String orderId,
    required String razorpayOrderId,
    required int amountPaise,
  }) async {
    await _supabase
        .from('orders')
        .update({
          'gateway': 'razorpay',
          'gateway_order_id': razorpayOrderId,
          'amount_paise': amountPaise,
        })
        .eq('id', orderId);
  }

  /// Mark order as paid with payment details
  Future<void> markPaid({
    required String orderId,
    required String paymentId,
    Map<String, dynamic>? gatewayResponse,
  }) async {
    await _supabase
        .from('orders')
        .update({
          'status': 'paid',
          'payment_id': paymentId,
          'payment_response': jsonEncode(gatewayResponse ?? {}),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  /// Mark order as failed/cancelled
  Future<void> markFailed({
    required String orderId,
    String? code,
    String? message,
    Map<String, dynamic>? errorData,
  }) async {
    await _supabase
        .from('orders')
        .update({
          'status': 'failed',
          if (code != null) 'error_code': code,
          if (message != null) 'error_message': message,
          if (errorData != null) 'error_response': jsonEncode(errorData),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }
}


