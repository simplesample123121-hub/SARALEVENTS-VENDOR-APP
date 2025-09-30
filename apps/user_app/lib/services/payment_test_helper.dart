import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'razorpay_service.dart';
import '../core/config/razorpay_config.dart';

/// Helper class for testing Razorpay integration
/// This should only be used in development/debug mode
class PaymentTestHelper {
  static final RazorpayService _razorpayService = RazorpayService();

  /// Test Razorpay configuration
  static bool testConfiguration() {
    try {
      RazorpayConfig.validate();
      if (kDebugMode) {
        debugPrint('✅ Razorpay configuration is valid');
        debugPrint('Key ID: ${RazorpayConfig.keyId}');
        debugPrint('App Name: ${RazorpayConfig.appName}');
        debugPrint('Currency: ${RazorpayConfig.currency}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Razorpay configuration error: $e');
      }
      return false;
    }
  }

  /// Test order creation (without actual payment)
  static Future<bool> testOrderCreation() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing order creation...');
      }

      final order = await _razorpayService.createOrderOnServer(
        amountInPaise: 10000, // ₹100
        currency: 'INR',
        receipt: 'test_${DateTime.now().millisecondsSinceEpoch}',
        notes: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (order['id'] != null) {
        if (kDebugMode) {
          debugPrint('✅ Order created successfully: ${order['id']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Order creation failed: No order ID returned');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Order creation error: $e');
      }
      return false;
    }
  }

  /// Test Razorpay initialization
  static bool testInitialization() {
    try {
      _razorpayService.init(
        onSuccess: (paymentId, responseData) {
          if (kDebugMode) {
            debugPrint('✅ Payment success callback working');
          }
        },
        onError: (code, message, errorData) {
          if (kDebugMode) {
            debugPrint('✅ Payment error callback working');
          }
        },
        onExternalWallet: (walletName) {
          if (kDebugMode) {
            debugPrint('✅ External wallet callback working');
          }
        },
      );

      if (_razorpayService.isInitialized) {
        if (kDebugMode) {
          debugPrint('✅ Razorpay service initialized successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Razorpay service initialization failed');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Razorpay initialization error: $e');
      }
      return false;
    }
  }

  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    if (!kDebugMode) {
      return {'error': false}; // Don't run tests in release mode
    }

    final results = <String, bool>{};

    if (kDebugMode) {
      debugPrint('🧪 Starting Razorpay integration tests...');
    }

    // Test 1: Configuration
    results['configuration'] = testConfiguration();

    // Test 2: Initialization
    results['initialization'] = testInitialization();

    // Test 3: Order Creation
    results['order_creation'] = await testOrderCreation();

    // Overall result
    results['overall'] = results.values.every((result) => result);

    if (kDebugMode) {
      debugPrint('🧪 Test Results:');
      results.forEach((test, result) {
        debugPrint('  ${result ? '✅' : '❌'} $test');
      });
    }

    return results;
  }

  /// Show test results in a dialog
  static void showTestResults(BuildContext context, Map<String, bool> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Razorpay Integration Tests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: results.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.error,
                    color: entry.value ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Dispose test resources
  static void dispose() {
    _razorpayService.dispose();
  }
}
