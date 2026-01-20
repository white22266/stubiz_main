import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../models/cart_item.dart';
import '../../services/chat_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../chat/chat_room.dart';
import '../cart/cart_page.dart';

class ProductDetailScreen extends StatefulWidget {
  final ListingItem item;
  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  bool _isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkCartStatus();
  }

  void _checkCartStatus() {
    setState(() {
      _isInCart = _cartService.isInCart(widget.item.id);
    });
  }

  Future<void> _addToCart() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    if (currentUser.uid == widget.item.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot buy your own product')),
      );
      return;
    }

    if (!widget.item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is not available')),
      );
      return;
    }

    try {
      final cartItem = CartItem.fromListing(widget.item);
      await _cartService.addItem(cartItem);
      setState(() {
        _isInCart = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _contactSeller(BuildContext context) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }
    if (currentUser.uid == widget.item.ownerId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This is your product')));
      return;
    }

    // Start Chat
    try {
      final chatId = await ChatService.startChat(widget.item.ownerId, widget.item.ownerName);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatId: chatId,
            otherUserId: widget.item.ownerId,
            otherUserName: widget.item.ownerName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _reportItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Report Item'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(hintText: 'Reason for reporting'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                MarketplaceService.reportItem(
                  widget.item.id,
                  widget.item.type.value,
                  reasonCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _reportItem(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: widget.item.imageUrl != null
                  ? Image.network(widget.item.imageUrl!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        widget.item.displayPrice,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${widget.item.category}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.item.description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.ownerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Seller',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isInCart ? null : _addToCart,
                icon: Icon(_isInCart ? Icons.check : Icons.shopping_cart),
                label: Text(_isInCart ? 'In Cart' : 'Add to Cart'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _contactSeller(context),
                icon: const Icon(Icons.chat),
                label: const Text('Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
