# Cart, Order, and Payment Module Documentation

## Overview

This documentation covers the newly implemented **Cart**, **Order**, and **Payment** modules for the StuBiz marketplace application. These modules provide complete e-commerce functionality including shopping cart management, order processing, and PayPal payment integration (sandbox/test mode).

---

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Models](#models)
4. [Services](#services)
5. [Screens](#screens)
6. [Integration Points](#integration-points)
7. [Data Flow](#data-flow)
8. [Security Features](#security-features)
9. [Testing](#testing)
10. [Future Enhancements](#future-enhancements)

---

## Features

### ✅ Implemented Features

#### Cart System
- **Local Storage**: Cart data persists across app sessions using SharedPreferences
- **Real-time Updates**: Cart badge shows item count in marketplace
- **Quantity Management**: Increment/decrement item quantities
- **Price Calculation**: Automatic subtotal, tax (6%), and total calculation
- **Item Removal**: Remove individual items or clear entire cart
- **Seller Grouping**: Items grouped by seller for better organization

#### Order Management
- **Order Creation**: Convert cart items to orders with shipping details
- **Order History**: View all past orders with status tracking
- **Order Details**: Complete order information including items, pricing, and shipping
- **Status Management**: Track order status (Pending, Processing, Completed, Cancelled)
- **Order Cancellation**: Cancel pending orders with product status reversion
- **Firestore Integration**: All orders stored in cloud database

#### Payment Processing
- **PayPal Mock Integration**: Sandbox/test payment processing
- **Transaction ID Generation**: Unique transaction IDs for each payment
- **Payment Verification**: Verify payment status
- **Payment Methods**: Support for multiple payment options (PayPal active)
- **Success Confirmation**: Payment success page with order details
- **Error Handling**: Graceful error handling with user feedback

---

## Architecture

### Directory Structure

```
lib/
├── models/
│   ├── cart_item.dart          # Cart item data model
│   └── order.dart              # Order and OrderItem models
├── services/
│   ├── cart_service.dart       # Cart management logic
│   ├── order_service.dart      # Order operations with Firestore
│   └── payment_service.dart    # Payment processing logic
└── screens/
    ├── cart/
    │   └── cart_page.dart      # Shopping cart UI
    ├── checkout/
    │   ├── checkout_page.dart  # Checkout form and payment
    │   └── payment_success_page.dart  # Payment confirmation
    └── orders/
        ├── order_history_page.dart    # List of user orders
        └── order_detail_page.dart     # Individual order details
```

---

## Models

### CartItem

Represents an item in the shopping cart.

**Properties:**
- `productId`: Unique product identifier
- `productName`: Name of the product
- `price`: Unit price
- `quantity`: Number of items
- `imageUrl`: Product image URL
- `sellerId`: Seller's user ID
- `sellerName`: Seller's display name
- `category`: Product category
- `addedAt`: Timestamp when added to cart

**Methods:**
- `toMap()`: Convert to Map for local storage
- `fromMap()`: Create from Map
- `fromListing()`: Create from ListingItem
- `totalPrice`: Calculated total (price × quantity)

### Order

Represents a completed order.

**Properties:**
- `id`: Firestore document ID
- `userId`: Buyer's user ID
- `userName`: Buyer's name
- `userEmail`: Buyer's email
- `items`: List of OrderItem objects
- `subtotal`: Sum of all items
- `tax`: Tax amount (6%)
- `total`: Final amount
- `status`: OrderStatus enum
- `paymentId`: Payment transaction ID
- `paymentMethod`: Payment method used
- `shippingAddress`: Delivery address
- `phoneNumber`: Contact number
- `notes`: Optional order notes
- `createdAt`: Order creation timestamp
- `updatedAt`: Last update timestamp

**Methods:**
- `toMap()`: Convert to Firestore document
- `fromFirestore()`: Create from Firestore document
- `formattedDate`: Human-readable date
- `formattedTime`: Human-readable time
- `totalItems`: Total quantity of items

### OrderItem

Represents a single item within an order.

**Properties:**
- `productId`: Product identifier
- `productName`: Product name
- `price`: Unit price at time of order
- `quantity`: Quantity ordered
- `imageUrl`: Product image
- `sellerId`: Seller ID
- `sellerName`: Seller name

---

## Services

### CartService

Singleton service managing shopping cart operations.

**Key Features:**
- Local persistence using SharedPreferences
- ChangeNotifier for reactive UI updates
- Automatic price calculations

**Methods:**
```dart
// Load cart from storage
Future<void> loadCart()

// Add item to cart
Future<void> addItem(CartItem item)

// Remove item from cart
Future<void> removeItem(String productId)

// Update quantity
Future<void> updateQuantity(String productId, int quantity)

// Increment/decrement quantity
Future<void> incrementQuantity(String productId)
Future<void> decrementQuantity(String productId)

// Clear entire cart
Future<void> clearCart()

// Check if product is in cart
bool isInCart(String productId)

// Get item quantity
int getItemQuantity(String productId)

// Group items by seller
Map<String, List<CartItem>> groupBySeller()
```

**Properties:**
```dart
List<CartItem> items          // All cart items
int itemCount                 // Number of unique items
int totalQuantity             // Total quantity of all items
double subtotal               // Sum before tax
double tax                    // 6% tax
double total                  // Final total
bool isEmpty                  // Cart empty check
```

### OrderService

Static service handling order operations with Firestore.

**Methods:**
```dart
// Create new order
static Future<String> createOrder({
  required List<CartItem> cartItems,
  required String shippingAddress,
  required String phoneNumber,
  String? notes,
  String? paymentId,
  String? paymentMethod,
})

// Get user's orders (Stream)
static Stream<List<Order>> getUserOrders()

// Get single order by ID
static Future<Order?> getOrderById(String orderId)

// Update order status
static Future<void> updateOrderStatus(
  String orderId,
  OrderStatus status,
)

// Cancel order
static Future<void> cancelOrder(String orderId)

// Get seller's orders (Stream)
static Stream<List<Order>> getSellerOrders(String sellerId)

// Get all orders - Admin only (Stream)
static Stream<List<Order>> getAllOrders()

// Get order statistics
static Future<Map<String, dynamic>> getOrderStatistics(String userId)

// Add payment info to order
static Future<void> addPaymentInfo(
  String orderId,
  String paymentId,
  String paymentMethod,
)

// Delete order - Admin only
static Future<void> deleteOrder(String orderId)
```

**Firestore Collection:**
- Collection name: `orders`
- Auto-generated document IDs
- Server timestamps for `createdAt` and `updatedAt`

### PaymentService

Static service for payment processing (mock PayPal implementation).

**Methods:**
```dart
// Process PayPal payment (Mock)
static Future<PaymentResult> processPayPalPayment({
  required double amount,
  required String currency,
  required String description,
  String? userEmail,
})

// Verify payment status
static Future<PaymentResult> verifyPayment(String transactionId)

// Refund payment (Mock)
static Future<PaymentResult> refundPayment({
  required String transactionId,
  required double amount,
  String? reason,
})

// Get available payment methods
static List<PaymentMethod> getAvailablePaymentMethods()

// Validate payment amount
static bool validateAmount(double amount)

// Format currency
static String formatCurrency(double amount, {String currency = 'RM'})

// Calculate PayPal fee
static double calculatePayPalFee(double amount)

// Get sandbox info
static Map<String, dynamic> getSandboxInfo()
```

**Payment Configuration:**
- Mode: Sandbox/Test
- Success Rate: 90% (for testing)
- Processing Delay: 2 seconds
- Transaction ID Format: `PAYPAL-{timestamp}-{random}`

---

## Screens

### CartPage

Shopping cart interface with Material Design 3.

**Features:**
- Empty cart state with call-to-action
- List of cart items with images
- Quantity controls (+/-)
- Item removal with confirmation
- Clear cart option
- Price summary (subtotal, tax, total)
- Proceed to checkout button

**Navigation:**
- Accessed from Marketplace AppBar cart icon
- Can navigate to CheckoutPage

### CheckoutPage

Checkout form and payment selection.

**Features:**
- Order summary with item preview
- Shipping information form
  - Address (required)
  - Phone number (required)
  - Order notes (optional)
- Payment method selection
  - PayPal (active)
  - Credit/Debit Card (coming soon)
  - Bank Transfer (coming soon)
- Price breakdown
- Sandbox mode indicator
- Pay button with loading state

**Validation:**
- Form validation for required fields
- User authentication check
- Cart empty check

### PaymentSuccessPage

Payment confirmation screen.

**Features:**
- Success animation
- Order ID display
- Transaction ID with copy function
- Amount paid
- Payment method
- View order details button
- Back to home button
- Email confirmation notice

### OrderHistoryPage

List of user's orders.

**Features:**
- Empty state for no orders
- Order cards with:
  - Order ID (shortened)
  - Status badge with color coding
  - Date and time
  - Item count
  - Total amount
  - Item preview (first 3 items)
- Real-time updates via Firestore stream
- Tap to view order details

### OrderDetailPage

Complete order information.

**Features:**
- Status header with icon
- Order information section
- List of all items with images
- Price summary
- Shipping information
- Order notes (if any)
- Cancel order option (for pending orders)

**Status Colors:**
- Pending: Orange
- Processing: Blue
- Completed: Green
- Cancelled: Red

---

## Integration Points

### Marketplace Integration

#### marketplace_home.dart
- Added cart icon in AppBar
- Badge showing item count
- Real-time cart updates
- Navigate to CartPage on tap

#### product_detail.dart
- "Add to Cart" button
- Cart status indicator
- Validation checks:
  - User authentication
  - Product availability
  - Not own product
- Success snackbar with "View Cart" action

### Profile Integration

#### profile_page.dart
- Added "Order History" menu item
- Navigate to OrderHistoryPage

---

## Data Flow

### Add to Cart Flow

```
Product Detail Screen
    ↓
[Add to Cart Button]
    ↓
Validate User & Product
    ↓
Create CartItem from ListingItem
    ↓
CartService.addItem()
    ↓
Save to SharedPreferences
    ↓
Notify Listeners
    ↓
Update UI (Badge, Button State)
```

### Checkout Flow

```
Cart Page
    ↓
[Proceed to Checkout]
    ↓
Checkout Page
    ↓
Fill Shipping Form
    ↓
Select Payment Method
    ↓
[Pay Button]
    ↓
Process Payment (PayPal Mock)
    ↓
Create Order in Firestore
    ↓
Update Product Status
    ↓
Clear Cart
    ↓
Payment Success Page
    ↓
View Order Details / Back to Home
```

### Order Status Flow

```
Pending → Processing → Completed
    ↓
Cancelled (from Pending only)
```

---

## Security Features

### 1. User Authentication
- All cart and order operations require authenticated user
- Firebase Auth integration
- User ID validation

### 2. Secure Data Storage
- Cart: Local storage (SharedPreferences)
- Orders: Cloud Firestore with security rules
- Payment info: Transaction IDs only (no sensitive data)

### 3. Encrypted Communication
- HTTPS for all API calls
- Firebase SDK handles encryption
- Secure token management

### 4. Input Validation
- Form validation for shipping details
- Amount validation for payments
- Product availability checks
- Owner verification (can't buy own products)

### 5. Payment Security (Mock Mode)
- Sandbox environment clearly indicated
- No real payment processing
- Transaction ID generation for testing
- Mock credentials (not hardcoded in production)

---

## Testing

### Manual Testing Checklist

#### Cart Functionality
- ✅ Add product to cart
- ✅ Update quantity (increment/decrement)
- ✅ Remove item from cart
- ✅ Clear entire cart
- ✅ Cart persistence across sessions
- ✅ Cart badge updates
- ✅ Price calculations

#### Order Management
- ✅ Create order from cart
- ✅ View order history
- ✅ View order details
- ✅ Cancel pending order
- ✅ Order status updates
- ✅ Product status updates

#### Payment Processing
- ✅ PayPal mock payment
- ✅ Transaction ID generation
- ✅ Payment success flow
- ✅ Payment failure handling
- ✅ Payment verification

#### Integration
- ✅ Marketplace cart icon
- ✅ Product detail add to cart
- ✅ Profile order history
- ✅ Navigation flow
- ✅ Real-time updates

### Code Quality

```bash
flutter analyze
```

**Results:**
- ✅ No errors
- ⚠️ 8 info/warnings (deprecation notices, style suggestions)
- All critical issues resolved

---

## Future Enhancements

### Phase 1: Payment Integration
- [ ] Real PayPal SDK integration
- [ ] Stripe payment gateway
- [ ] Credit/Debit card processing
- [ ] Bank transfer support
- [ ] E-wallet integration (Touch 'n Go, GrabPay)

### Phase 2: Cart Features
- [ ] Save for later
- [ ] Wishlist integration
- [ ] Cart sharing
- [ ] Promo code support
- [ ] Bulk actions

### Phase 3: Order Features
- [ ] Order tracking
- [ ] Delivery status updates
- [ ] Order rating and review
- [ ] Reorder functionality
- [ ] Invoice generation (PDF)
- [ ] Email notifications

### Phase 4: Seller Features
- [ ] Seller dashboard
- [ ] Sales analytics
- [ ] Order fulfillment
- [ ] Inventory management
- [ ] Shipping integration

### Phase 5: Admin Features
- [ ] Order management dashboard
- [ ] Payment reconciliation
- [ ] Refund processing
- [ ] Dispute resolution
- [ ] Sales reports

### Phase 6: Performance
- [ ] Pagination for order history
- [ ] Image optimization
- [ ] Caching strategies
- [ ] Offline mode
- [ ] Background sync

---

## API Reference

### Firestore Collections

#### orders
```json
{
  "userId": "string",
  "userName": "string",
  "userEmail": "string",
  "items": [
    {
      "productId": "string",
      "productName": "string",
      "price": "number",
      "quantity": "number",
      "imageUrl": "string",
      "sellerId": "string",
      "sellerName": "string"
    }
  ],
  "subtotal": "number",
  "tax": "number",
  "total": "number",
  "status": "string",
  "paymentId": "string",
  "paymentMethod": "string",
  "shippingAddress": "string",
  "phoneNumber": "string",
  "notes": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### SharedPreferences Keys

- `shopping_cart`: JSON array of cart items

---

## Dependencies

### Existing Dependencies
- `firebase_core`: ^3.14.0
- `firebase_auth`: ^5.7.0
- `cloud_firestore`: ^5.0.1
- `shared_preferences`: ^2.2.3

### No Additional Dependencies Required
All features implemented using existing packages.

---

## Troubleshooting

### Common Issues

#### Cart not persisting
**Solution:** Ensure `CartService().loadCart()` is called on app start

#### Order not creating
**Solution:** Check Firestore security rules and user authentication

#### Payment always failing
**Solution:** Mock payment has 90% success rate for testing; retry if needed

#### Cart badge not updating
**Solution:** Ensure proper listener setup in marketplace_home.dart

---

## Support

For issues or questions:
1. Check this documentation
2. Review code comments
3. Check Flutter/Firestore documentation
4. Contact development team

---

## Changelog

### Version 1.0.0 (Current)
- ✅ Cart system with local caching
- ✅ Order management with Firestore
- ✅ PayPal mock payment integration
- ✅ Complete UI/UX implementation
- ✅ Material Design 3 compliance
- ✅ Integration with existing marketplace

---

## License

This module is part of the StuBiz project and follows the same license.

---

**Last Updated:** January 2026
**Author:** Development Team
**Version:** 1.0.0
