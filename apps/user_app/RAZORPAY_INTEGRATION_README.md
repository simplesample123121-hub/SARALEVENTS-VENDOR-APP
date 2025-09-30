# Razorpay Payment Integration

This document provides comprehensive information about the Razorpay payment integration implemented in the Saral Events User App.

## Overview

The Razorpay integration provides a secure, production-ready payment solution for the user app. It includes:

- **Secure credential management**
- **Comprehensive error handling**
- **Payment verification**
- **Order management**
- **User-friendly payment flow**
- **Success/failure handling**

## Architecture

### Components

1. **RazorpayConfig** (`lib/core/config/razorpay_config.dart`)
   - Centralized configuration for Razorpay credentials
   - Production keys management
   - App-specific settings

2. **RazorpayService** (`lib/services/razorpay_service.dart`)
   - Core Razorpay integration
   - Order creation and management
   - Payment processing
   - Enhanced error handling

3. **PaymentService** (`lib/services/payment_service.dart`)
   - High-level payment orchestration
   - User experience management
   - Comprehensive payment flow

4. **PaymentResultScreen** (`lib/checkout/payment_result_screen.dart`)
   - Success/failure UI
   - Payment details display
   - Retry functionality

5. **Supabase Edge Function** (`supabase/functions/create_razorpay_order/`)
   - Server-side order creation
   - Secure credential handling
   - Database logging

## Configuration

### Credentials

The integration uses live production credentials:

```dart
// Live production keys
key_id: rzp_live_RNhz4a9K9h6SNQ
key_secret: YO1h1gkF3upgD2fClwPVrfjG
```

**⚠️ Security Note**: In a production environment, these credentials should be:
- Stored as environment variables
- Never committed to version control
- Rotated regularly
- Access-restricted

### App Configuration

```dart
static const String appName = 'Saral Events';
static const String currency = 'INR';
static const String themeColor = '#FDBB42';
static const bool autoCapture = true;
static const int timeout = 300; // 5 minutes
```

## Payment Flow

### 1. User Initiates Payment

```dart
await _paymentService.processPayment(
  context: context,
  checkoutState: checkoutState,
  onSuccess: () {
    // Handle successful payment
  },
  onFailure: () {
    // Handle payment failure
  },
);
```

### 2. Order Creation

- Client calls Supabase Edge Function
- Server creates Razorpay order with secure credentials
- Order details logged to database
- Order ID returned to client

### 3. Payment Processing

- Razorpay checkout opens with order details
- User completes payment
- Payment result handled with comprehensive callbacks

### 4. Result Handling

- **Success**: Payment details displayed, user continues
- **Failure**: Error details shown, retry option provided
- **External Wallet**: User redirected to external payment app

## Database Schema

### payment_orders Table

```sql
CREATE TABLE payment_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  razorpay_order_id TEXT UNIQUE NOT NULL,
  amount BIGINT NOT NULL, -- Amount in paise
  currency TEXT NOT NULL DEFAULT 'INR',
  receipt TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'created',
  notes JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Security Features

### 1. Credential Protection
- Server-side credential storage
- No client-side secret exposure
- Environment variable support

### 2. Order Validation
- Amount validation
- Currency validation
- Receipt uniqueness

### 3. Error Handling
- Comprehensive error logging
- User-friendly error messages
- Retry mechanisms

### 4. Data Integrity
- Payment signature verification (server-side)
- Order status tracking
- Audit trail maintenance

## Error Handling

### Client-Side Errors

```dart
onError: (code, message, errorData) {
  // Handle payment errors
  // Show user-friendly messages
  // Provide retry options
}
```

### Server-Side Errors

- Razorpay API errors
- Database connection issues
- Validation failures
- Network timeouts

## Testing

### Test Mode

For testing, use Razorpay's test credentials:

```dart
// Test credentials (replace with actual test keys)
static const String testKeyId = 'rzp_test_...';
static const String testKeySecret = '...';
```

### Test Scenarios

1. **Successful Payment**
   - Valid card details
   - Sufficient balance
   - Network connectivity

2. **Failed Payment**
   - Invalid card details
   - Insufficient balance
   - Network issues

3. **Edge Cases**
   - Payment timeout
   - User cancellation
   - External wallet selection

## Deployment

### 1. Environment Variables

Set the following environment variables in your Supabase project:

```bash
RAZORPAY_KEY_ID=rzp_live_RNhz4a9K9h6SNQ
RAZORPAY_KEY_SECRET=YO1h1gkF3upgD2fClwPVrfjG
```

### 2. Database Migration

Run the payment_orders table migration:

```sql
-- Execute the migration file
-- supabase/migrations/20241201_create_payment_orders.sql
```

### 3. Edge Function Deployment

Deploy the Razorpay order creation function:

```bash
supabase functions deploy create_razorpay_order
```

## Monitoring

### Logging

The integration includes comprehensive logging:

- Payment initiation
- Order creation
- Payment success/failure
- Error details
- User actions

### Metrics to Monitor

1. **Payment Success Rate**
2. **Average Payment Time**
3. **Error Frequency**
4. **User Drop-off Points**

## Best Practices

### 1. Security
- Never expose secret keys
- Use HTTPS in production
- Implement proper authentication
- Regular security audits

### 2. User Experience
- Clear error messages
- Loading indicators
- Retry mechanisms
- Payment confirmation

### 3. Performance
- Optimize payment flow
- Minimize API calls
- Cache configuration
- Handle network issues

### 4. Maintenance
- Regular dependency updates
- Monitor Razorpay API changes
- Test payment flows
- Update documentation

## Troubleshooting

### Common Issues

1. **Payment Not Processing**
   - Check network connectivity
   - Verify Razorpay credentials
   - Check order creation logs

2. **Order Creation Fails**
   - Verify Supabase function deployment
   - Check environment variables
   - Review function logs

3. **Payment Verification Issues**
   - Ensure server-side verification
   - Check signature validation
   - Review webhook configuration

### Debug Mode

Enable debug logging:

```dart
if (kDebugMode) {
  debugPrint('Payment details: $details');
}
```

## Support

For issues related to:

- **Razorpay Integration**: Check Razorpay documentation
- **Supabase Functions**: Review Supabase logs
- **App-specific Issues**: Check app logs and error handling

## Version History

- **v1.0.0**: Initial Razorpay integration
  - Basic payment processing
  - Order management
  - Error handling
  - Success/failure screens

---

**Note**: This integration is production-ready but should be thoroughly tested before deployment. Always follow security best practices and keep credentials secure.
