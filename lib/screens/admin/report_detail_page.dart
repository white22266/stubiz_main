import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const ReportDetailPage({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  ListingItem? _item;
  bool _loading = true;
  final TextEditingController _warningController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  @override
  void dispose() {
    _warningController.dispose();
    super.dispose();
  }

  Future<void> _loadItemDetails() async {
    try {
      final itemId = widget.reportData['itemId'] ?? '';
      final itemTypeStr = widget.reportData['itemType'] ?? 'product';

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

  Future<void> _sendWarning() async {
    if (_warningController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a warning message')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('warnings').add({
        'userId': _item?.ownerId ?? '',
        'itemId': widget.reportData['itemId'],
        'itemType': widget.reportData['itemType'],
        'itemName': _item?.name ?? '',
        'reason': widget.reportData['reason'],
        'warningMessage': _warningController.text.trim(),
        'status': 'pending', // pending, resolved
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warning sent successfully')),
      );
      _warningController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending warning: $e')),
      );
    }
  }

  Future<void> _suspendItem() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Item'),
        content: const Text(
          'This will suspend the item (not delete). The owner can resubmit after fixing violations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                // Update item status to suspended
                await FirebaseFirestore.instance
                    .collection(_item!.type.collectionName)
                    .doc(_item!.id)
                    .update({'status': 'suspended'});

                // Create warning
                await FirebaseFirestore.instance.collection('warnings').add({
                  'userId': _item!.ownerId,
                  'itemId': _item!.id,
                  'itemType': widget.reportData['itemType'],
                  'itemName': _item!.name,
                  'reason': widget.reportData['reason'],
                  'warningMessage': 'Your item has been suspended due to violations.',
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item suspended successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'This will PERMANENTLY delete the item. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await MarketplaceService.deleteItem(_item!.id, _item!.type);
              await _dismissReport();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _dismissReport() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Info
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text(
                                'Report Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Reason', widget.reportData['reason'] ?? 'No reason'),
                          _buildInfoRow('Type', widget.reportData['itemType'] ?? 'Unknown'),
                          _buildInfoRow('Item ID', widget.reportData['itemId'] ?? 'Unknown'),
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
                            _buildInfoRow('Owner', _item!.ownerName),
                            _buildInfoRow('Owner Email', _item!.ownerEmail),
                            _buildInfoRow('Status', _item!.statusDisplayText),
                            if (_item!.price != null)
                              _buildInfoRow('Price', _item!.displayPrice),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Warning Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Warning',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _warningController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Enter warning message...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text('Send Warning'),
                                onPressed: _sendWarning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Dismiss Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  await _dismissReport();
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Report dismissed')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.pause_circle),
                                label: const Text('Suspend Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                onPressed: _suspendItem,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.delete_forever),
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
            width: 120,
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
