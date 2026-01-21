import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import '../marketplace/product_detail.dart';
import '../exchange/exchange_detail.dart';
import '../promotion/promotion_detail.dart';
import '../marketplace/edit_product.dart';
import '../exchange/edit_exchange.dart';
import '../promotion/edit_promotion.dart';

class MyListingsPage extends StatelessWidget {
  final ListingType type;
  const MyListingsPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Error: Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('My ${type.displayName}s')),
      body: StreamBuilder<List<ListingItem>>(
        stream: MarketplaceService.streamListings(type).map(
          (items) => items.where((item) => item.ownerId == user.uid).toList(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return EmptyState(
              title: 'No listings yet',
              message:
                  'You haven\'t posted any ${type.displayName.toLowerCase()} yet.',
              icon: Icons.layers_clear,
            );
          }

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image),
                  title: Text(item.name, maxLines: 1),
                  subtitle: Text(
                    item.statusDisplayText,
                    style: TextStyle(
                      color: item.isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editItem(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, item),
                      ),
                    ],
                  ),
                  onTap: () => _viewItem(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _viewItem(BuildContext context, ListingItem item) {
    Widget detailPage;
    switch (item.type) {
      case ListingType.product:
        detailPage = ProductDetailScreen(item: item);
        break;
      case ListingType.exchange:
        detailPage = ExchangeDetail(item: item);
        break;
      case ListingType.promotion:
        detailPage = PromotionDetailScreen(item: item);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => detailPage));
  }

  void _editItem(BuildContext context, ListingItem item) {
    Widget editPage;
    switch (item.type) {
      case ListingType.product:
        editPage = EditProductScreen(product: item);
        break;
      case ListingType.exchange:
        editPage = EditExchangeScreen(exchange: item);
        break;
      case ListingType.promotion:
        editPage = EditPromotionScreen(promotion: item);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => editPage));
  }

  void _confirmDelete(BuildContext context, ListingItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await MarketplaceService.deleteItem(item.id, item.type);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
