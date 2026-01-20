import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _items = [];
  bool _isLoaded = false;

  static const String _cartKey = 'shopping_cart';

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get tax => subtotal * 0.06; // 6% tax

  double get total => subtotal + tax;

  bool get isEmpty => _items.isEmpty;

  // Load cart from local storage
  Future<void> loadCart() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null) {
        final List<dynamic> decoded = json.decode(cartJson);
        _items = decoded.map((item) => CartItem.fromMap(item)).toList();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_items.map((item) => item.toMap()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // Add item to cart
  Future<void> addItem(CartItem item) async {
    // Check if item already exists
    final existingIndex =
        _items.indexWhere((i) => i.productId == item.productId);

    if (existingIndex >= 0) {
      // Update quantity
      _items[existingIndex].quantity += item.quantity;
    } else {
      // Add new item
      _items.add(item);
    }

    await _saveCart();
    notifyListeners();
  }

  // Remove item from cart
  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    await _saveCart();
    notifyListeners();
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      await _saveCart();
      notifyListeners();
    }
  }

  // Increment quantity
  Future<void> incrementQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index].quantity++;
      await _saveCart();
      notifyListeners();
    }
  }

  // Decrement quantity
  Future<void> decrementQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        await _saveCart();
        notifyListeners();
      } else {
        await removeItem(productId);
      }
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // Get item quantity
  int getItemQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        price: 0,
        sellerId: '',
        sellerName: '',
        category: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Get cart item by product ID
  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Group items by seller
  Map<String, List<CartItem>> groupBySeller() {
    final Map<String, List<CartItem>> grouped = {};

    for (var item in _items) {
      if (!grouped.containsKey(item.sellerId)) {
        grouped[item.sellerId] = [];
      }
      grouped[item.sellerId]!.add(item);
    }

    return grouped;
  }

  // Calculate total for specific seller
  double getSellerTotal(String sellerId) {
    return _items
        .where((item) => item.sellerId == sellerId)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}
