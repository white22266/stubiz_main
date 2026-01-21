import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/listing_item.dart';

class WarningDetailPage extends StatefulWidget {
  final String warningId;
  final Map<String, dynamic> warningData;

  const WarningDetailPage({
    super.key,
    required this.warningId,
    required this.warningData,
  });

  @override
  State<WarningDetailPage> createState() => _WarningDetailPageState();
}

class _WarningDetailPageState extends State<WarningDetailPage> {
  ListingItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    try {
      final itemId = widget.warningData['itemId'] ?? '';
      final itemTypeStr = widget.warningData['itemType'] ?? 'product';

      ListingType type;
      if (itemTypeStr == 'exchange') {
        type = ListingType.exchange;
      } else if (itemTypeStr == 'promotion') {
        type = ListingType.promotion;
      } else {
        type = ListingType.product;
      }

      final doc = await FirebaseFirestore.instance
          .collection(type.collectionName)
          .doc(itemId)
          .get();

      if (doc.exists) {
        setState(() {
          _item = ListingItem.fromFirestore(doc, type);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Delete the item
                await FirebaseFirestore.instance
                    .collection(_item!.type.collectionName)
                    .doc(_item!.id)
                    .delete();

                // Update warning status
                await FirebaseFirestore.instance
                    .collection('warnings')
                    .doc(widget.warningId)
                    .update({'status': 'resolved'});

                if (!mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _editItem() async {
    // Navigate to edit page based on item type
    if (_item == null) return;

    String routeName = '';
    switch (_item!.type) {
      case ListingType.product:
        routeName = '/edit-product';
        break;
      case ListingType.exchange:
        routeName = '/edit-exchange';
        break;
      case ListingType.promotion:
        routeName = '/edit-promotion';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to $routeName with item: ${_item!.id}')),
    );
  }

  Future<void> _resubmitItem() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resubmit Item'),
        content: const Text(
          'This will change the item status back to available and request admin review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update item status to available
                await FirebaseFirestore.instance
                    .collection(_item!.type.collectionName)
                    .doc(_item!.id)
                    .update({'status': 'available'});

                // Update warning status
                await FirebaseFirestore.instance
                    .collection('warnings')
                    .doc(widget.warningId)
                    .update({'status': 'resolved'});

                if (!mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item resubmitted for review')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.warningData['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warning Details'),
        backgroundColor: Colors.orange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Info Card
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 32),
                              const SizedBox(width: 12),
                              const Text(
                                'Warning Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Item Name', widget.warningData['itemName'] ?? 'Unknown'),
                          _buildInfoRow('Reason', widget.warningData['reason'] ?? 'No reason'),
                          _buildInfoRow('Status', status.toUpperCase()),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Warning Message:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(widget.warningData['warningMessage'] ?? 'No message'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item Details
                  if (_item != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Item Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_item!.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _item!.imageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Name', _item!.name),
                            _buildInfoRow('Description', _item!.description),
                            _buildInfoRow('Category', _item!.category),
                            _buildInfoRow('Status', _item!.statusDisplayText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions (only if warning is pending)
                    if (status == 'pending')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You can edit your item to fix the violation, delete it, or resubmit for review.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Item'),
                                  onPressed: _editItem,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Resubmit for Review'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: _resubmitItem,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: _deleteItem,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Item not found or has been deleted'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
