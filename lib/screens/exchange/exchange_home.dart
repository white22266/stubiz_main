import 'package:flutter/material.dart';

import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';
import 'exchange_form.dart';
import 'exchange_detail.dart';

class ExchangeHome extends StatefulWidget {
  const ExchangeHome({super.key});

  @override
  State<ExchangeHome> createState() => _ExchangeHomeState();
}

class _ExchangeHomeState extends State<ExchangeHome> {
  String? _selectedTag; // null = All
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Old-mode: 3 tags only (match your ExchangeForm categories)
  final List<String> _tags = const ['Electronics', 'Books', 'Others'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    _searchController.text = _searchQuery;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Exchange'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search title, description, wanted item...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _applySearch(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => _applySearch(ctx),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _applySearch(BuildContext dialogContext) {
    setState(() => _searchQuery = _searchController.text.trim());
    Navigator.pop(dialogContext);
  }

  bool _matchesSearch(ListingItem item, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    final title = item.name.toLowerCase(); // exchange title -> item.name
    final desc = item.description.toLowerCase();
    final wanted = (item.wantedItem ?? '').toLowerCase();

    return title.contains(q) || desc.contains(q) || wanted.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Exchange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 3-tag chips (old mode)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedTag == null,
                  onSelected: (_) => setState(() => _selectedTag = null),
                ),
                const SizedBox(width: 8),
                ..._tags.map((t) {
                  final selected = _selectedTag == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedTag = t),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Search indicator
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Searching: "$_searchQuery"',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _searchQuery = ''),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<ListingItem>>(
              // IMPORTANT: your service uses streamListings, not streamExchanges
              stream: MarketplaceService.streamListings(
                ListingType.exchange,
                category: _selectedTag, // null = no filter
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var items = snapshot.data ?? [];

                // Local search filter (old mode)
                if (_searchQuery.isNotEmpty) {
                  items = items
                      .where((it) => _matchesSearch(it, _searchQuery))
                      .toList();
                }

                if (items.isEmpty) {
                  return const Center(child: Text('No exchange posts found.'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Firestore stream auto-updates; this just triggers rebuild.
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _buildCard(context, items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExchangeForm()),
          );
        },
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Exchange'),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ListingItem item) {
    final wanted = (item.wantedItem ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // IMPORTANT: your detail page class is ExchangeDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExchangeDetail(item: item)),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: item.imageUrl == null
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 40),
                    )
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name, // exchange title
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (wanted.isNotEmpty)
                      Text(
                        'Wanted: $wanted',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.category,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          item.timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
