import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'razorpay_service.dart';
import '../checkout/checkout_state.dart';
import '../checkout/payment_result_screen.dart';

/// Comprehensive payment service that handles the complete payment flow
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final RazorpayService _razorpayService = RazorpayService();

  /// Process payment with comprehensive error handling and user feedback
  Future<void> processPayment({
    required BuildContext context,
    required CheckoutState checkoutState,
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) async {
    try {
      // Validate checkout state
      if (checkoutState.items.isEmpty) {
        _showError(context, 'No items in cart');
        return;
      }

      if (checkoutState.billingDetails == null) {
        _showError(context, 'Billing details not provided');
        return;
      }

      // Get user details
      final user = Supabase.instance.client.auth.currentUser;
      final billingDetails = checkoutState.billingDetails!;
      
      // Prepare payment details
      final amountPaise = (checkoutState.totalPrice * 100).round();
      final receipt = 'ord_${DateTime.now().millisecondsSinceEpoch}';
      
      if (kDebugMode) {
        debugPrint('Processing payment:');
        debugPrint('Amount: ₹${checkoutState.totalPrice} (${amountPaise} paise)');
        debugPrint('Items: ${checkoutState.items.length}');
        debugPrint('User: ${billingDetails.name} (${billingDetails.email})');
      }

      // Create order on server
      final order = await _razorpayService.createOrderOnServer(
        amountInPaise: amountPaise,
        currency: 'INR',
        receipt: receipt,
        notes: {
          'app': 'saral_user',
          'user_id': user?.id ?? 'anonymous',
          'user_name': billingDetails.name,
          'user_email': billingDetails.email,
          'user_phone': billingDetails.phone,
          'items_count': checkoutState.items.length.toString(),
          'total_amount': checkoutState.totalPrice.toString(),
          'event_date': billingDetails.eventDate?.toIso8601String(),
          'message_to_vendor': billingDetails.messageToVendor,
        },
      );

      // Initialize Razorpay
      _razorpayService.init(
        onSuccess: (paymentId, responseData) {
          _handlePaymentSuccess(
            context: context,
            paymentId: paymentId,
            responseData: responseData,
            checkoutState: checkoutState,
            onSuccessCallback: onSuccess,
          );
        },
        onError: (code, message, errorData) {
          _handlePaymentError(
            context: context,
            code: code,
            message: message,
            errorData: errorData,
            checkoutState: checkoutState,
            onSuccess: onSuccess,
            onFailure: onFailure,
          );
        },
        onExternalWallet: (walletName) {
          _showInfo(context, 'Redirecting to $walletName...');
        },
      );

      // Open Razorpay checkout
      _razorpayService.openCheckout(
        amountInPaise: amountPaise,
        name: 'Saral Events',
        description: 'Service payment for ${checkoutState.items.length} item(s)',
        orderId: order['id'] as String,
        prefillName: billingDetails.name,
        prefillEmail: billingDetails.email,
        prefillContact: billingDetails.phone,
        notes: {
          'app': 'saral_user',
          'user_id': user?.id ?? 'anonymous',
          'items_count': checkoutState.items.length.toString(),
          'total_amount': checkoutState.totalPrice.toString(),
        },
      );

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Payment processing error: $e');
      }
      _showError(context, 'Failed to process payment: $e');
      onFailure();
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess({
    required BuildContext context,
    required String paymentId,
    required Map<String, dynamic> responseData,
    required CheckoutState checkoutState,
    required VoidCallback onSuccessCallback,
  }) {
    if (kDebugMode) {
      debugPrint('Payment successful: $paymentId');
      debugPrint('Response data: $responseData');
    }

    // Show success screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentResultScreen(
          isSuccess: true,
          paymentId: paymentId,
          responseData: responseData,
          onContinue: () {
            Navigator.of(context).pop(); // Close result screen
            onSuccessCallback();
          },
        ),
      ),
    );
  }

  /// Handle payment error
  void _handlePaymentError({
    required BuildContext context,
    required String code,
    required String message,
    required Map<String, dynamic>? errorData,
    required CheckoutState checkoutState,
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) {
    if (kDebugMode) {
      debugPrint('Payment failed: $code - $message');
      debugPrint('Error data: $errorData');
    }

    // Show error screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentResultScreen(
          isSuccess: false,
          errorMessage: message,
          responseData: errorData,
          onRetry: () {
            Navigator.of(context).pop(); // Close error screen
            // Retry payment
            processPayment(
              context: context,
              checkoutState: checkoutState,
              onSuccess: onSuccess,
              onFailure: onFailure,
            );
          },
          onContinue: () {
            Navigator.of(context).pop(); // Close error screen
            onFailure();
          },
        ),
      ),
    );
  }

  /// Show error message
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show info message
  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _razorpayService.dispose();
  }
}
