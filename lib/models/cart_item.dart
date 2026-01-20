class CartItem {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  int quantity;
  final String category;
  final DateTime addedAt;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.quantity = 1,
    required this.category,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  double get totalPrice => price * quantity;

  // Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'quantity': quantity,
      'category': category,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Create from Map (local storage)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      quantity: map['quantity'] ?? 1,
      category: map['category'] ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'])
          : DateTime.now(),
    );
  }

  // Create CartItem from ListingItem
  factory CartItem.fromListing(dynamic listing, {int quantity = 1}) {
    return CartItem(
      productId: listing.id,
      productName: listing.name,
      price: listing.price ?? 0.0,
      imageUrl: listing.imageUrl,
      sellerId: listing.ownerId,
      sellerName: listing.ownerName,
      quantity: quantity,
      category: listing.category,
    );
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    double? price,
    String? imageUrl,
    String? sellerId,
    String? sellerName,
    int? quantity,
    String? category,
    DateTime? addedAt,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
