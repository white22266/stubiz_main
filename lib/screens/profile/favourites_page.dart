import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/listing_item.dart';
import '../../services/auth_service.dart';
import '../../services/marketplace_service.dart';
import '../marketplace/product_detail.dart';
import '../exchange/exchange_detail.dart';
import '../promotion/promotion_detail.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: favRef.snapshots(),
        builder: (context, favSnap) {
          if (favSnap.hasError) {
            return Center(child: Text('Error: ${favSnap.error}'));
          }
          if (!favSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favDocs = favSnap.data!.docs;
          if (favDocs.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }

          return FutureBuilder<List<ListingItem>>(
            future: _loadFavoriteItems(favDocs),
            builder: (context, itemsSnap) {
              if (itemsSnap.hasError) {
                return Center(child: Text('Error: ${itemsSnap.error}'));
              }
              if (!itemsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = itemsSnap.data!;
              if (items.isEmpty) {
                return const Center(child: Text('No favorites found'));
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(item.name),
                    subtitle: Text(
                      item.type == ListingType.product
                          ? item.displayPrice
                          : item.type.displayName,
                    ),
                    onTap: () => _openDetail(context, item),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<ListingItem>> _loadFavoriteItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> favDocs,
  ) async {
    final results = <ListingItem>[];

    for (final d in favDocs) {
      final data = d.data();
      final itemId = (data['itemId'] ?? '').toString();
      final typeStr = (data['type'] ?? '').toString();

      if (itemId.isEmpty || typeStr.isEmpty) continue;

      final type = _parseType(typeStr);
      if (type == null) continue;

      final item = await MarketplaceService.getListingById(type, itemId);
      if (item != null) results.add(item);
    }

    return results;
  }

  ListingType? _parseType(String v) {
    switch (v) {
      case 'product':
        return ListingType.product;
      case 'exchange':
        return ListingType.exchange;
      case 'promotion':
        return ListingType.promotion;
      default:
        return null;
    }
  }

  void _openDetail(BuildContext context, ListingItem item) {
    if (item.type == ListingType.product) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(item: item)),
      );
      return;
    }

    if (item.type == ListingType.exchange) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExchangeDetailScreen(item: item)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PromotionDetailScreen(item: item)),
    );
  }
}
