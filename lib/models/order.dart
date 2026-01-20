import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'],
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
    );
  }

  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      productId: cartItem.productId,
      productName: cartItem.productName,
      price: cartItem.price,
      quantity: cartItem.quantity,
      imageUrl: cartItem.imageUrl,
      sellerId: cartItem.sellerId,
      sellerName: cartItem.sellerName,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final OrderStatus status;
  final String? paymentId;
  final String? paymentMethod;
  final String? shippingAddress;
  final String? phoneNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    required this.total,
    this.status = OrderStatus.pending,
    this.paymentId,
    this.paymentMethod,
    this.shippingAddress,
    this.phoneNumber,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status.value,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    OrderStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'processing':
          return OrderStatus.processing;
        case 'completed':
          return OrderStatus.completed;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: parseStatus(data['status']),
      paymentId: data['paymentId'],
      paymentMethod: data['paymentMethod'],
      shippingAddress: data['shippingAddress'],
      phoneNumber: data['phoneNumber'],
      notes: data['notes'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    OrderStatus? status,
    String? paymentId,
    String? paymentMethod,
    String? shippingAddress,
    String? phoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
