import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final SupabaseClient _supabase;

  OrderRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await _supabase
          .from('orders')
          .select('id, status, total_amount, created_at, gateway, gateway_order_id, payment_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching orders: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return Map<String, dynamic>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching order $orderId: $e');
      }
      return null;
    }
  }
}


