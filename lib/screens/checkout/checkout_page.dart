import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import 'payment_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final CartService _cartService = CartService();
  
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'paypal';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      _phoneController.text = user.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(),
                    const Divider(height: 1, thickness: 8),
                    _buildShippingForm(),
                    const Divider(height: 1, thickness: 8),
                    _buildPaymentMethods(),
                    const Divider(height: 1, thickness: 8),
                    _buildPriceSummary(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          _buildCheckoutButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_cartService.totalQuantity} item${_cartService.totalQuantity > 1 ? 's' : ''} in your cart',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...(_cartService.items.take(3).map((item) => _buildOrderItem(item))),
          if (_cartService.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${_cartService.items.length - 3} more item${_cartService.items.length - 3 > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item.productName} (x${item.quantity})',
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'RM ${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Shipping Address *',
              hintText: 'Enter your complete address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your shipping address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'e.g., +60123456789',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Order Notes (Optional)',
              hintText: 'Any special instructions?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = PaymentService.getAvailablePaymentMethods();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...methods.map((method) => _buildPaymentMethodTile(method)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a sandbox/test payment. No real money will be charged.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: method.id,
        groupValue: _selectedPaymentMethod,
        onChanged: method.isEnabled
            ? (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              }
            : null,
        title: Text(
          method.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: method.isEnabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          method.description,
          style: TextStyle(
            fontSize: 12,
            color: method.isEnabled ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        secondary: Icon(
          _getPaymentIcon(method.icon),
          color: method.isEnabled ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String icon) {
    switch (icon) {
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPriceSummary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', _cartService.subtotal),
          const SizedBox(height: 8),
          _buildPriceRow('Tax (6%)', _cartService.tax),
          const Divider(height: 24),
          _buildPriceRow('Total', _cartService.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _isProcessing ? null : _processCheckout,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pay RM ${_cartService.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Process payment
      final paymentResult = await PaymentService.processPayPalPayment(
        amount: _cartService.total,
        currency: 'RM',
        description: 'StuBiz Order - ${_cartService.totalQuantity} items',
        userEmail: FirebaseAuth.instance.currentUser?.email,
      );

      if (!paymentResult.isSuccess) {
        throw Exception(paymentResult.message ?? 'Payment failed');
      }

      // Step 2: Create order
      final orderId = await OrderService.createOrder(
        cartItems: _cartService.items,
        shippingAddress: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        paymentId: paymentResult.transactionId,
        paymentMethod: 'PayPal',
      );

      // Step 3: Clear cart
      await _cartService.clearCart();

      // Step 4: Navigate to success page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              orderId: orderId,
              transactionId: paymentResult.transactionId!,
              amount: _cartService.total,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
