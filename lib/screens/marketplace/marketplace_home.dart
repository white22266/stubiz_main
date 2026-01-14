import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/product.dart';
import '../../services/local_storage.dart';
import '../../widgets/empty_state.dart';
import 'product_detail.dart';
import 'add_product.dart';

class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});

  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  final categories = [
    'All',
    'Books',
    'Electronics',
    'Stationery',
    'Services',
    'Others'
  ];
  String selectedCategory = 'All';

  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Used Calculator',
      price: 15,
      description: 'Good condition, rarely used',
      category: 'Electronics',
    ),
    Product(
      id: '2',
      name: 'Notebook Pack',
      price: 10,
      description: '5 notebooks included',
      category: 'Stationery',
    ),
  ];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final saved = await LocalStorage.loadProducts();
    if (saved.isNotEmpty) {
      setState(() {
        _products
          ..clear()
          ..addAll(saved);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' || p.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: filteredProducts.isEmpty
                ? EmptyState(
                    icon: Icons.storefront,
                    title: 'No Products Yet',
                    message:
                        'Be the first to list an item on the marketplace.',
                    actionText: 'Add Product',
                    onAction: _addProduct,
                  )
                : AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration:
                              const Duration(milliseconds: 450),
                          columnCount: 2,
                          child: SlideAnimation(
                            verticalOffset: 40,
                            child: FadeInAnimation(
                              child: _buildProductCard(product),
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
              onSelected: (_) =>
                  setState(() => selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  // PRODUCT CARD
  Widget _buildProductCard(Product product) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetail(product: product),
          ),
        );
      },
      onLongPress: () => _showOptions(product),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade300,
                      Colors.blue.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          product.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isFavorite
                              ? Colors.red
                              : Colors.white,
                        ),
                        onPressed: () async {
                          setState(() {
                            product.isFavorite =
                                !product.isFavorite;
                          });
                          await LocalStorage.saveProducts(
                              _products);
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge(product.category),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 11),
      ),
    );
  }

  // ADD
  void _addProduct() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
          builder: (_) => const AddProduct()),
    );

    if (product != null) {
      setState(() => _products.add(product));
      await LocalStorage.saveProducts(_products);
    }
  }

  // EDIT
  void _editProduct(Product product) async {
    final updated = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
          builder: (_) => AddProduct(product: product)),
    );

    if (updated != null) {
      setState(() {
        final index = _products
            .indexWhere((p) => p.id == product.id);
        _products[index] = updated;
      });
      await LocalStorage.saveProducts(_products);
    }
  }

  // DELETE
  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              setState(() => _products.remove(product));
              await LocalStorage.saveProducts(_products);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // OPTIONS
  void _showOptions(Product product) {
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
              _editProduct(product);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
          ),
        ],
      ),
    );
  }

  // SEARCH
  void _showSearch() {
    showSearch(
      context: context,
      delegate: _MarketplaceSearchDelegate(
        onChanged: (q) =>
            setState(() => _searchQuery = q),
      ),
    );
  }
}

// SEARCH DELEGATE
class _MarketplaceSearchDelegate extends SearchDelegate {
  final Function(String) onChanged;

  _MarketplaceSearchDelegate({required this.onChanged});

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
