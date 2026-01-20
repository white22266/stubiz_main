import 'dart:math';
import 'package:flutter/foundation.dart';

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
}

class PaymentResult {
  final PaymentStatus status;
  final String? transactionId;
  final String? message;
  final DateTime timestamp;

  PaymentResult({
    required this.status,
    this.transactionId,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == PaymentStatus.success;
}

class PaymentService {
  // Mock PayPal configuration (sandbox/test mode)
  static const String _paypalClientId = 'MOCK_PAYPAL_CLIENT_ID';
  static const bool _isSandboxMode = true;

  // Simulate payment processing delay
  static const Duration _processingDelay = Duration(seconds: 2);

  /// Process PayPal payment (Mock implementation)
  /// In production, this would integrate with actual PayPal SDK
  static Future<PaymentResult> processPayPalPayment({
    required double amount,
    required String currency,
    required String description,
    String? userEmail,
  }) async {
    try {
      debugPrint('=== MOCK PAYPAL PAYMENT ===');
      debugPrint('Mode: ${_isSandboxMode ? 'SANDBOX' : 'PRODUCTION'}');
      debugPrint('Amount: $currency $amount');
      debugPrint('Description: $description');
      debugPrint('User Email: $userEmail');

      // Simulate processing delay
      await Future.delayed(_processingDelay);

      // Generate mock transaction ID
      final transactionId = _generateTransactionId();

      // Simulate 90% success rate (for testing purposes)
      final random = Random();
      final isSuccess = random.nextInt(100) < 90;

      if (isSuccess) {
        debugPrint('✓ Payment successful');
        debugPrint('Transaction ID: $transactionId');
        
        return PaymentResult(
          status: PaymentStatus.success,
          transactionId: transactionId,
          message: 'Payment completed successfully',
        );
      } else {
        debugPrint('✗ Payment failed');
        
        return PaymentResult(
          status: PaymentStatus.failed,
          message: 'Payment processing failed. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('✗ Payment error: $e');
      
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'An error occurred during payment processing',
      );
    }
  }

  /// Verify payment status (Mock implementation)
  static Future<PaymentResult> verifyPayment(String transactionId) async {
    try {
      debugPrint('Verifying payment: $transactionId');
      
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock verification - always return success for valid format
      if (transactionId.startsWith('PAYPAL-')) {
        return PaymentResult(
          status: PaymentStatus.success,
          transactionId: transactionId,
          message: 'Payment verified successfully',
        );
      } else {
        return PaymentResult(
          status: PaymentStatus.failed,
          message: 'Invalid transaction ID',
        );
      }
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Verification failed: $e',
      );
    }
  }

  /// Refund payment (Mock implementation)
  static Future<PaymentResult> refundPayment({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      debugPrint('=== MOCK PAYPAL REFUND ===');
      debugPrint('Transaction ID: $transactionId');
      debugPrint('Amount: $amount');
      debugPrint('Reason: $reason');

      await Future.delayed(const Duration(seconds: 1));

      final refundId = _generateTransactionId(prefix: 'REFUND');

      debugPrint('✓ Refund successful');
      debugPrint('Refund ID: $refundId');

      return PaymentResult(
        status: PaymentStatus.success,
        transactionId: refundId,
        message: 'Refund processed successfully',
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Refund failed: $e',
      );
    }
  }

  /// Get payment methods available
  static List<PaymentMethod> getAvailablePaymentMethods() {
    return [
      PaymentMethod(
        id: 'paypal',
        name: 'PayPal',
        description: 'Pay securely with PayPal',
        icon: 'paypal',
        isEnabled: true,
      ),
      PaymentMethod(
        id: 'credit_card',
        name: 'Credit/Debit Card',
        description: 'Pay with Visa, Mastercard, or Amex',
        icon: 'credit_card',
        isEnabled: false, // Not implemented yet
      ),
      PaymentMethod(
        id: 'bank_transfer',
        name: 'Bank Transfer',
        description: 'Direct bank transfer',
        icon: 'bank',
        isEnabled: false, // Not implemented yet
      ),
    ];
  }

  /// Generate mock transaction ID
  static String _generateTransactionId({String prefix = 'PAYPAL'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return '$prefix-$timestamp-$random';
  }

  /// Validate payment amount
  static bool validateAmount(double amount) {
    return amount > 0 && amount <= 999999.99;
  }

  /// Format currency
  static String formatCurrency(double amount, {String currency = 'RM'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Calculate PayPal fee (mock - typically 3.4% + RM 2.00)
  static double calculatePayPalFee(double amount) {
    return (amount * 0.034) + 2.00;
  }

  /// Get sandbox credentials info
  static Map<String, dynamic> getSandboxInfo() {
    return {
      'mode': _isSandboxMode ? 'sandbox' : 'production',
      'clientId': _paypalClientId,
      'note': 'This is a mock implementation for testing purposes',
      'testCards': [
        {
          'type': 'Visa',
          'number': '4111 1111 1111 1111',
          'cvv': '123',
          'expiry': '12/25',
        },
        {
          'type': 'Mastercard',
          'number': '5555 5555 5555 4444',
          'cvv': '123',
          'expiry': '12/25',
        },
      ],
    };
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isEnabled;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isEnabled = true,
  });
}
