import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';

class MyListingsPage extends StatelessWidget {
  final ListingType type;
  const MyListingsPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Error: Not logged in')));

    return Scaffold(
      appBar: AppBar(
        title: Text('My ${type.displayName}s'),
      ), // e.g., My Products
      body: StreamBuilder<List<ListingItem>>(
        // NOTE: You might need to update marketplace_service.dart to accept 'ownerId' parameter in streamListings
        // Or filter it client side. Assuming updated service from previous conversation handles filters.
        stream: MarketplaceService.streamListings(type).map(
          (items) => items.where((item) => item.ownerId == user.uid).toList(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
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
                child: ListTile(
                  leading: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
                  title: Text(item.name, maxLines: 1),
                  subtitle: Text(
                    item.statusDisplayText,
                    style: TextStyle(
                      color: item.isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
