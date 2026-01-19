import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';
import 'promotion_detail.dart';
import 'promotion_form.dart';

class PromotionHome extends StatelessWidget {
  const PromotionHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Businesses')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.store),
        label: const Text('Promote Business'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PromotionForm()),
        ),
      ),
      body: StreamBuilder<List<ListingItem>>(
        // Automatically fetches ONLY approved promotions for students
        stream: MarketplaceService.streamListings(ListingType.promotion),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text('No active promotions right now.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PromotionDetailScreen(item: item),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Banner
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.purple[100],
                          child: item.imageUrl != null
                              ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                              : const Icon(
                                  Icons.store,
                                  size: 50,
                                  color: Colors.purple,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.category,
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            if (item.location != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.location!,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
