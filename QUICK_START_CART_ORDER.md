# Quick Start Guide: Cart, Order & Payment Modules

## 🚀 Getting Started

This guide will help you quickly understand and use the new Cart, Order, and Payment modules in the StuBiz app.

---

## 📦 What's New

### 1. Shopping Cart
- Add products to cart from product details
- View cart from marketplace (cart icon)
- Manage quantities and remove items
- See real-time price calculations

### 2. Orders
- Checkout with shipping information
- Track order history
- View order details
- Cancel pending orders

### 3. Payment
- Mock PayPal payment (sandbox mode)
- Payment confirmation
- Transaction tracking

---

## 🎯 Quick Usage

### For Users

#### Adding Items to Cart
1. Browse marketplace
2. Tap on a product
3. Click "Add to Cart" button
4. View cart icon badge update

#### Checking Out
1. Tap cart icon in marketplace
2. Review items and quantities
3. Tap "Proceed to Checkout"
4. Fill in shipping details
5. Select PayPal payment
6. Tap "Pay" button
7. View confirmation page

#### Viewing Orders
1. Go to Profile tab
2. Tap "Order History"
3. View all your orders
4. Tap any order for details

---

## 👨‍💻 For Developers

### File Structure

```
lib/
├── models/
│   ├── cart_item.dart       # Cart item model
│   └── order.dart           # Order models
├── services/
│   ├── cart_service.dart    # Cart logic
│   ├── order_service.dart   # Order operations
│   └── payment_service.dart # Payment processing
└── screens/
    ├── cart/
    │   └── cart_page.dart
    ├── checkout/
    │   ├── checkout_page.dart
    │   └── payment_success_page.dart
    └── orders/
        ├── order_history_page.dart
        └── order_detail_page.dart
```

### Key Services

#### CartService (Singleton)
```dart
final cartService = CartService();

// Load cart
await cartService.loadCart();

// Add item
await cartService.addItem(cartItem);

// Get totals
double total = cartService.total;
int itemCount = cartService.itemCount;

// Listen to changes
cartService.addListener(() {
  // Cart updated
});
```

#### OrderService (Static)
```dart
// Create order
String orderId = await OrderService.createOrder(
  cartItems: cartItems,
  shippingAddress: address,
  phoneNumber: phone,
  paymentId: transactionId,
  paymentMethod: 'PayPal',
);

// Get user orders (Stream)
Stream<List<Order>> orders = OrderService.getUserOrders();

// Get order by ID
Order? order = await OrderService.getOrderById(orderId);

// Cancel order
await OrderService.cancelOrder(orderId);
```

#### PaymentService (Static)
```dart
// Process payment (Mock)
PaymentResult result = await PaymentService.processPayPalPayment(
  amount: 100.00,
  currency: 'RM',
  description: 'Order payment',
  userEmail: 'user@example.com',
);

if (result.isSuccess) {
  String transactionId = result.transactionId!;
  // Proceed with order creation
}
```

---

## 🔧 Integration Points

### Adding Cart to New Screens

```dart
import '../../services/cart_service.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _cartService.loadCart();
    _cartService.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Screen'),
        actions: [
          // Cart badge
          Badge(
            label: Text('${_cartService.itemCount}'),
            child: IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: // Your content
    );
  }
}
```

### Adding to Cart from Product

```dart
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';

Future<void> addToCart(ListingItem product) async {
  final cartService = CartService();
  final cartItem = CartItem.fromListing(product);
  
  await cartService.addItem(cartItem);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Added to cart')),
  );
}
```

---

## 🗄️ Database Schema

### Firestore: orders Collection

```
orders/
  {orderId}/
    - userId: string
    - userName: string
    - userEmail: string
    - items: array
      - productId: string
      - productName: string
      - price: number
      - quantity: number
      - imageUrl: string
      - sellerId: string
      - sellerName: string
    - subtotal: number
    - tax: number
    - total: number
    - status: string (pending/processing/completed/cancelled)
    - paymentId: string
    - paymentMethod: string
    - shippingAddress: string
    - phoneNumber: string
    - notes: string
    - createdAt: timestamp
    - updatedAt: timestamp
```

### SharedPreferences: shopping_cart

```json
[
  {
    "productId": "string",
    "productName": "string",
    "price": 0.0,
    "quantity": 1,
    "imageUrl": "string",
    "sellerId": "string",
    "sellerName": "string",
    "category": "string",
    "addedAt": "ISO8601 string"
  }
]
```

---

## 🎨 UI Components

### Cart Badge
```dart
Stack(
  children: [
    IconButton(
      icon: Icon(Icons.shopping_cart),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartPage()),
      ),
    ),
    if (cartService.itemCount > 0)
      Positioned(
        right: 8,
        top: 8,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${cartService.itemCount}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
  ],
)
```

### Order Status Chip
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: statusColor,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(statusIcon, size: 14),
      SizedBox(width: 4),
      Text(status.displayName),
    ],
  ),
)
```

---

## 🧪 Testing

### Test Cart Operations
```dart
void testCart() async {
  final cartService = CartService();
  await cartService.loadCart();
  
  // Add item
  final item = CartItem(
    productId: 'test1',
    productName: 'Test Product',
    price: 10.00,
    sellerId: 'seller1',
    sellerName: 'Test Seller',
    category: 'Test',
  );
  
  await cartService.addItem(item);
  assert(cartService.itemCount == 1);
  
  // Update quantity
  await cartService.incrementQuantity('test1');
  assert(cartService.getItemQuantity('test1') == 2);
  
  // Remove item
  await cartService.removeItem('test1');
  assert(cartService.isEmpty);
  
  print('✅ Cart tests passed');
}
```

### Test Order Creation
```dart
void testOrder() async {
  final cartItems = [
    CartItem(
      productId: 'prod1',
      productName: 'Product 1',
      price: 50.00,
      sellerId: 'seller1',
      sellerName: 'Seller 1',
      category: 'Test',
    ),
  ];
  
  try {
    final orderId = await OrderService.createOrder(
      cartItems: cartItems,
      shippingAddress: '123 Test St',
      phoneNumber: '+60123456789',
      paymentId: 'PAYPAL-TEST-123',
      paymentMethod: 'PayPal',
    );
    
    print('✅ Order created: $orderId');
  } catch (e) {
    print('❌ Order creation failed: $e');
  }
}
```

### Test Payment
```dart
void testPayment() async {
  final result = await PaymentService.processPayPalPayment(
    amount: 100.00,
    currency: 'RM',
    description: 'Test payment',
  );
  
  if (result.isSuccess) {
    print('✅ Payment successful: ${result.transactionId}');
  } else {
    print('❌ Payment failed: ${result.message}');
  }
}
```

---

## 🔐 Security Notes

### Important
- ⚠️ PayPal integration is in **SANDBOX MODE** (test only)
- ⚠️ No real payments are processed
- ⚠️ Transaction IDs are mock-generated
- ⚠️ For production, implement real PayPal SDK

### User Validation
```dart
// Always check user authentication
final user = AuthService.currentUser;
if (user == null) {
  // Show login prompt
  return;
}

// Check product ownership
if (user.uid == product.ownerId) {
  // Can't buy own product
  return;
}
```

---

## 📊 Analytics Integration (Future)

### Track Cart Events
```dart
// Add to cart
analytics.logEvent(
  name: 'add_to_cart',
  parameters: {
    'item_id': product.id,
    'item_name': product.name,
    'price': product.price,
  },
);

// Begin checkout
analytics.logEvent(
  name: 'begin_checkout',
  parameters: {
    'value': cartService.total,
    'currency': 'MYR',
    'items': cartService.itemCount,
  },
);

// Purchase
analytics.logEvent(
  name: 'purchase',
  parameters: {
    'transaction_id': orderId,
    'value': order.total,
    'currency': 'MYR',
  },
);
```

---

## 🐛 Common Issues

### Cart not loading
**Solution:** Call `await cartService.loadCart()` in initState

### Order creation fails
**Check:**
- User is authenticated
- Firestore rules allow write
- All required fields provided

### Payment always fails
**Note:** Mock payment has 90% success rate for testing

---

## 📚 Additional Resources

- [Full Documentation](CART_ORDER_PAYMENT_DOCUMENTATION.md)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io/)

---

## 🤝 Contributing

When adding features:
1. Follow existing code style
2. Add comments for complex logic
3. Update documentation
4. Test thoroughly
5. Create pull request

---

## ✅ Checklist for Production

Before going live:
- [ ] Replace mock PayPal with real SDK
- [ ] Update Firestore security rules
- [ ] Add proper error logging
- [ ] Implement analytics
- [ ] Add email notifications
- [ ] Test on real devices
- [ ] Performance optimization
- [ ] Security audit

---

**Happy Coding! 🚀**
