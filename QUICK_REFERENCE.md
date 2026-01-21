# StuBiz - Quick Reference Guide

## 🚀 Quick Start

### Run the App
```bash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

---

## 📱 Key Features Overview

### 1. **Shopping & Orders**
- Browse products in Marketplace
- Add to cart (local storage)
- Checkout with shipping details
- Mock PayPal payment
- Track order status
- Cancel pending orders

### 2. **Selling**
- Post products for sale
- View "My Sales" dashboard
- Process orders (Pending → Processing → Completed)
- Track earnings
- Edit/Delete own products

### 3. **Business Promotions**
- Create business promotions
- Add location with Google Maps geocoding
- View on interactive map
- Edit/Delete own promotions

### 4. **Exchange Zone**
- Post items for exchange
- Specify wanted items
- Chat with interested users
- Edit/Delete own posts

### 5. **Chat System**
- Real-time messaging
- Contact sellers/buyers
- Message history

---

## 🎯 User Workflows

### **Buy a Product**
1. Marketplace → Browse products
2. Tap product → View details
3. Tap "Add to Cart"
4. Cart icon → View cart
5. "Proceed to Checkout"
6. Enter shipping address & phone
7. "Place Order"
8. Complete payment
9. View order in "Order History"

### **Sell a Product**
1. Profile → "My Products"
2. Tap "+" to add product
3. Fill form (name, price, description, category, image)
4. Submit
5. Wait for orders
6. Profile → "My Sales"
7. View order → "Mark as Processing"
8. After delivery → "Mark as Completed"

### **Edit Your Product**
1. Marketplace → Your product
2. Tap edit icon (pencil)
3. Modify details
4. Save changes

### **Delete Your Product**
1. Marketplace → Your product
2. Tap delete icon (trash)
3. Confirm deletion

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── student_navigation.dart      # Bottom navigation
├── models/
│   ├── listing_item.dart       # Product/Exchange/Promotion model
│   ├── cart_item.dart          # Cart item model
│   └── order.dart              # Order model
├── services/
│   ├── auth_service.dart       # Authentication
│   ├── marketplace_service.dart # CRUD operations
│   ├── cart_service.dart       # Cart management
│   ├── order_service.dart      # Order management
│   └── payment_service.dart    # Payment processing
├── screens/
│   ├── auth/                   # Login/Register
│   ├── marketplace/            # Products
│   │   ├── marketplace_home.dart
│   │   ├── product_detail.dart
│   │   ├── add_product.dart
│   │   └── edit_product.dart
│   ├── cart/
│   │   └── cart_page.dart
│   ├── checkout/
│   │   ├── checkout_page.dart
│   │   └── payment_success_page.dart
│   ├── orders/
│   │   ├── order_history_page.dart
│   │   ├── order_detail_page.dart
│   │   ├── seller_orders_page.dart
│   │   └── seller_order_detail_page.dart
│   ├── promotion/
│   │   ├── promotion_home.dart
│   │   ├── promotion_detail.dart
│   │   ├── promotion_form.dart
│   │   └── edit_promotion.dart
│   ├── exchange/
│   │   ├── exchange_home.dart
│   │   ├── exchange_detail.dart
│   │   ├── exchange_form.dart
│   │   └── edit_exchange.dart
│   ├── chat/
│   │   └── chat_room.dart
│   └── profile/
│       ├── profile_page.dart
│       └── my_listings_page.dart
```

---

## 🔧 Key Services

### **AuthService**
- `login()` - User login
- `register()` - User registration
- `logout()` - User logout
- `currentUser` - Get current user

### **MarketplaceService**
- `createProduct()` - Add new product
- `updateProduct()` - Edit product
- `deleteItem()` - Delete product/promotion/exchange
- `streamListings()` - Get real-time product list
- `createPromotion()` - Add promotion
- `updatePromotion()` - Edit promotion
- `createExchange()` - Add exchange
- `updateExchange()` - Edit exchange

### **CartService**
- `addItem()` - Add to cart
- `removeItem()` - Remove from cart
- `updateQuantity()` - Change quantity
- `getItems()` - Get all cart items
- `clearCart()` - Empty cart
- `getTotalPrice()` - Calculate total

### **OrderService**
- `createOrder()` - Place new order
- `getUserOrders()` - Get buyer's orders
- `getSellerOrders()` - Get seller's orders
- `updateOrderStatus()` - Change order status
- `cancelOrder()` - Cancel order

### **PaymentService**
- `processPayment()` - Mock PayPal payment
- `generateTransactionId()` - Create transaction ID

---

## 🎨 UI Components

### **Common Widgets**
- `FilledButton` - Primary actions
- `OutlinedButton` - Secondary actions
- `Card` - Content containers
- `ListTile` - List items
- `TextField` - Input fields
- `DropdownButton` - Selection menus
- `CircularProgressIndicator` - Loading states
- `SnackBar` - Feedback messages

### **Custom Components**
- Status chips (Pending, Processing, Completed)
- Price displays with currency
- Product cards with images
- Order item cards
- Cart badge

---

## 🔐 Security Notes

### **Authentication**
- Firebase Authentication required
- Session management automatic
- Secure token handling

### **Authorization**
- Edit/Delete only for owners
- `AuthService.currentUser?.uid == item.ownerId`
- Firestore security rules enforce access

### **Data Validation**
- Form validation on all inputs
- Price must be > 0
- Required fields checked
- Phone number format validation

---

## 🐛 Common Issues & Solutions

### **Issue: Cart not persisting**
**Solution:** Check SharedPreferences initialization in `CartService`

### **Issue: Orders not showing**
**Solution:** Verify Firestore collection name is 'orders'

### **Issue: Payment fails**
**Solution:** Check `PaymentService` mock implementation

### **Issue: Images not uploading**
**Solution:** Verify Firebase Storage rules and permissions

### **Issue: Edit button not showing**
**Solution:** Ensure user is logged in and owns the item

---

## 📊 Order Status Flow

```
┌─────────┐
│ Pending │ ← Order placed by buyer
└────┬────┘
     │ Seller: "Mark as Processing"
     ↓
┌────────────┐
│ Processing │ ← Seller preparing items
└─────┬──────┘
      │ Seller: "Mark as Completed"
      ↓
┌───────────┐
│ Completed │ ← Order delivered
└───────────┘

Buyer can cancel only when status is "Pending"
```

---

## 🎯 Testing Checklist

### **Before Release**
- [ ] Test login/logout
- [ ] Test product CRUD
- [ ] Test cart operations
- [ ] Test checkout flow
- [ ] Test order creation
- [ ] Test order status updates
- [ ] Test edit functionality
- [ ] Test delete functionality
- [ ] Test chat system
- [ ] Test on different screen sizes
- [ ] Test error handling
- [ ] Test offline behavior

---

## 📞 Troubleshooting

### **App won't build**
```bash
flutter clean
flutter pub get
flutter run
```

### **Firestore permission denied**
Check Firebase console → Firestore → Rules

### **Images not loading**
Check Firebase Storage rules and internet connection

### **Login fails**
Verify Firebase Authentication is enabled

---

## 🔗 Important Links

- **GitHub:** https://github.com/white22266/stubiz_main
- **Firebase Console:** https://console.firebase.google.com
- **Flutter Docs:** https://docs.flutter.dev
- **Material Design:** https://m3.material.io

---

## 📝 Quick Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle

# Clean build
flutter clean

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check for updates
flutter upgrade
```

---

## 🎓 Key Concepts

### **State Management**
- StatefulWidget for local state
- StreamBuilder for real-time data
- setState() for UI updates

### **Navigation**
- Navigator.push() for new screens
- Navigator.pop() to go back
- MaterialPageRoute for transitions

### **Data Flow**
```
User Action → Service Method → Firestore → Stream → UI Update
```

### **Error Handling**
```dart
try {
  await service.method();
  // Show success
} catch (e) {
  // Show error
}
```

---

**Last Updated:** January 2026  
**Version:** 2.0.0
