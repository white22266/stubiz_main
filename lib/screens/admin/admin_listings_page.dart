import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/empty_state.dart';

class AdminListingsPage extends StatefulWidget {
  const AdminListingsPage({super.key});

  @override
  State<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends State<AdminListingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Biz'),
            Tab(text: 'Products'),
            Tab(text: 'Exchange'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPromotionList(), // Special logic for approvals
          _buildGenericList(ListingType.product),
          _buildGenericList(ListingType.exchange),
        ],
      ),
    );
  }

  // 1. Tab for Pending Promotions
  Widget _buildPromotionList() {
    return StreamBuilder<List<ListingItem>>(
      // Fetch ALL promotions (MarketplaceService needs to support isAdmin flag to show unapproved ones)
      stream: MarketplaceService.streamListings(
        ListingType.promotion,
        isAdmin: true,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        // Filter only Pending items
        final items = snapshot.data!.where((i) => !i.isApproved).toList();

        if (items.isEmpty)
          return const EmptyState(
            title: 'All Caught Up',
            message: 'No pending business approvals.',
          );

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Category: ${item.category}\n${item.description}',
                    ),
                    leading: const Icon(Icons.store, color: Colors.purple),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject'),
                          onPressed: () => MarketplaceService.deleteItem(
                            item.id,
                            ListingType.promotion,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => MarketplaceService.approvePromotion(
                            item.id,
                            true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. Generic Tab for Products/Exchanges
  Widget _buildGenericList(ListingType type) {
    return StreamBuilder<List<ListingItem>>(
      stream: MarketplaceService.streamListings(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;

        if (items.isEmpty)
          return EmptyState(
            title: 'No Items',
            message: 'No ${type.displayName}s found.',
          );

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image),
              title: Text(item.name),
              subtitle: Text('By: ${item.ownerName}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteItem(item),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteItem(ListingItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Delete?'),
        content: Text('Delete "${item.name}" from the database?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              MarketplaceService.deleteItem(item.id, item.type);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
