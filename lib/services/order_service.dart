import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as order_model;
import '../models/cart_item.dart';
// ignore_for_file: avoid_types_as_parameter_names

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _ordersCollection = 'orders';

  // Create new order
  static Future<String> createOrder({
    required List<CartItem> cartItems,
    required String shippingAddress,
    required String phoneNumber,
    String? notes,
    String? paymentId,
    String? paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Convert cart items to order items
      final orderItems = cartItems
          .map((item) => order_model.OrderItem.fromCartItem(item))
          .toList();

      // Calculate totals

      final subtotal = cartItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final tax = subtotal * 0.06; // 6% tax
      final total = subtotal + tax;

      // Create order object
      final order = order_model.Order(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName: userData['name'] ?? user.displayName ?? 'Unknown',
        userEmail: user.email ?? '',
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        total: total,
        status: order_model.OrderStatus.pending,
        paymentId: paymentId,
        paymentMethod: paymentMethod,
        shippingAddress: shippingAddress,
        phoneNumber: phoneNumber,
        notes: notes,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_ordersCollection)
          .add(order.toMap());

      // Update product status (optional - mark as pending)
      for (var item in cartItems) {
        await _updateProductStatus(item.productId, 'pending');
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user orders
  static Stream<List<order_model.Order>> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => order_model.Order.fromFirestore(doc))
              .toList();
        });
  }

  // Get single order by ID
  static Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) return null;

      return order_model.Order.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(
    String orderId,
    order_model.OrderStatus status,
  ) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If completed, update product status to sold
      if (status == order_model.OrderStatus.completed) {
        final order = await getOrderById(orderId);
        if (order != null) {
          for (var item in order.items) {
            await _updateProductStatus(item.productId, 'sold');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel order
  static Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, order_model.OrderStatus.cancelled);

      // Revert product status back to available
      final order = await getOrderById(orderId);
      if (order != null) {
        for (var item in order.items) {
          await _updateProductStatus(item.productId, 'available');
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Get orders by seller (for sellers to see their sales)
  static Stream<List<order_model.Order>> getSellerOrders(String sellerId) {
    // Note: Firestore doesn't support arrayContains with objects
    // So we fetch all orders and filter in memory
    return _firestore
        .collection(_ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => order_model.Order.fromFirestore(doc))
              .where(
                (order) => order.items.any((item) => item.sellerId == sellerId),
              )
              .toList();
        });
  }

  // Get all orders (admin only)
  static Stream<List<order_model.Order>> getAllOrders() {
    return _firestore
        .collection(_ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => order_model.Order.fromFirestore(doc))
              .toList();
        });
  }

  // Get order statistics
  static Future<Map<String, dynamic>> getOrderStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final orders = snapshot.docs
          .map((doc) => order_model.Order.fromFirestore(doc))
          .toList();

      int totalOrders = orders.length;
      int pendingOrders = orders
          .where((o) => o.status == order_model.OrderStatus.pending)
          .length;
      int completedOrders = orders
          .where((o) => o.status == order_model.OrderStatus.completed)
          .length;
      int cancelledOrders = orders
          .where((o) => o.status == order_model.OrderStatus.cancelled)
          .length;
      double totalSpent = orders
          .where((o) => o.status != order_model.OrderStatus.cancelled)
          .fold(0.0, (total, order) => total + order.total);

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  // Helper: Update product status
  static Future<void> _updateProductStatus(
    String productId,
    String status,
  ) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail if product doesn't exist or can't be updated
    }
  }

  // Add payment info to order
  static Future<void> addPaymentInfo(
    String orderId,
    String paymentId,
    String paymentMethod,
  ) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add payment info: $e');
    }
  }

  // Delete order (admin only)
  static Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }
}
