import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/exchange_item.dart';
import '../../services/local_storage.dart';
import '../../widgets/empty_state.dart';
import 'exchange_detail.dart';
import 'exchange_form.dart';

class ExchangeHome extends StatefulWidget {
  const ExchangeHome({super.key});

  @override
  State<ExchangeHome> createState() => _ExchangeHomeState();
}

class _ExchangeHomeState extends State<ExchangeHome> {
  final categories = ['All', 'Books', 'Electronics', 'Stationery', 'Others'];
  String selectedCategory = 'All';

  final List<ExchangeItem> _items = [
    ExchangeItem(
      id: '1',
      title: 'Old Notebook',
      description: 'Used but clean',
      wantedItem: 'Pen',
      category: 'Books',
    ),
    ExchangeItem(
      id: '2',
      title: 'Calculator',
      description: 'Works fine',
      wantedItem: 'USB',
      category: 'Electronics',
    ),
  ];

  String _searchQuery = '';
  String _wantedFilter = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final saved = await LocalStorage.loadExchanges();
    if (saved.isNotEmpty) {
      setState(() {
        _items
          ..clear()
          ..addAll(saved);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      final matchesSearch =
          item.title.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesWanted = _wantedFilter.isEmpty ||
          item.wantedItem.toLowerCase().contains(_wantedFilter.toLowerCase());

      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;

      return matchesSearch && matchesWanted && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Zone'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearch),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showWantedFilter,
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: filteredItems.isEmpty
                ? EmptyState(
                    icon: Icons.swap_horiz,
                    title: 'No Exchange Items',
                    message:
                        'Post an item to start exchanging with other students.',
                    actionText: 'Add Exchange Item',
                    onAction: _addItem,
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration:
                              const Duration(milliseconds: 400),
                          child: SlideAnimation(
                            horizontalOffset: 50,
                            child: FadeInAnimation(
                              child: _buildExchangeCard(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // CATEGORY CHIPS
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: selectedCategory == cat,
              onSelected: (_) => setState(() => selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  // EXCHANGE CARD
  Widget _buildExchangeCard(ExchangeItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExchangeDetail(item: item),
          ),
        );
      },
      onLongPress: () => _showOptions(item),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'exchange-${item.id}',
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade300,
                      Colors.orange.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.swap_horiz,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge(item.category),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildBadge('Wants ${item.wantedItem}'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BADGE
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  // SEARCH
  void _showSearch() {
    showSearch(
      context: context,
      delegate: _ExchangeSearchDelegate(
        onChanged: (q) => setState(() => _searchQuery = q),
      ),
    );
  }

  // WANTED FILTER
  void _showWantedFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        String temp = _wantedFilter;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Wanted Item',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Wanted item'),
                onChanged: (v) => temp = v,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _wantedFilter = temp);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ADD
  void _addItem() async {
    final item = await Navigator.push<ExchangeItem>(
      context,
      MaterialPageRoute(builder: (_) => const ExchangeForm()),
    );

    if (item != null) {
      setState(() => _items.add(item));
      await LocalStorage.saveExchanges(_items);
    }
  }

  // EDIT
  void _editItem(ExchangeItem item) async {
    final updated = await Navigator.push<ExchangeItem>(
      context,
      MaterialPageRoute(builder: (_) => ExchangeForm(item: item)),
    );

    if (updated != null) {
      setState(() {
        final index = _items.indexWhere((e) => e.id == item.id);
        _items[index] = updated;
      });
      await LocalStorage.saveExchanges(_items);
    }
  }

  // DELETE
  void _deleteItem(ExchangeItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exchange'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _items.remove(item));
              await LocalStorage.saveExchanges(_items);
              Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // OPTIONS
  void _showOptions(ExchangeItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _editItem(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
          ),
        ],
      ),
    );
  }
}

// SEARCH DELEGATE
class _ExchangeSearchDelegate extends SearchDelegate {
  final Function(String) onChanged;

  _ExchangeSearchDelegate({required this.onChanged});

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            onChanged('');
          },
        ),
      ];

  @override
  Widget buildResults(BuildContext context) {
    onChanged(query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    onChanged(query);
    return const SizedBox();
  }
}
