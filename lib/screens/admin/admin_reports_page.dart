import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/listing_item.dart'; // Need ListingType extension
import '../../services/marketplace_service.dart';
import '../../widgets/empty_state.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reported Items')),
      body: StreamBuilder<QuerySnapshot>(
        // Directly accessing 'reports' collection as defined in MarketplaceService.reportItem
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return const EmptyState(
              title: 'Clean Record',
              message: 'No active reports found.',
              icon: Icons.verified_user_outlined,
            );
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data() as Map<String, dynamic>;
              final reportId = reports[index].id;
              final itemId = data['itemId'] ?? '';
              final itemTypeStr = data['itemType'] ?? 'product';
              final reason = data['reason'] ?? 'No reason';

              // Helper to get ListingType from string string
              ListingType type;
              if (itemTypeStr == 'exchange') {
                type = ListingType.exchange;
              } else if (itemTypeStr == 'promotion') {
                type = ListingType.promotion;
              } else {
                type = ListingType.product;
              }
              return Card(
                color: Colors.red[50],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text('Reason: $reason'),
                  subtitle: Text('Type: $itemTypeStr\nID: $itemId'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dismiss Report Button
                      IconButton(
                        tooltip: 'Dismiss Report',
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => _dismissReport(reportId),
                      ),
                      // Delete Item Button (Nuclear Option)
                      IconButton(
                        tooltip: 'Delete Item',
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteItemAndReport(
                          context,
                          reportId,
                          itemId,
                          type,
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

  Future<void> _dismissReport(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .delete();
  }

  Future<void> _deleteItemAndReport(
    BuildContext context,
    String reportId,
    String itemId,
    ListingType type,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Action'),
        content: const Text(
          'This will DELETE the reported item permanently and close the report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // 1. Delete the item
              await MarketplaceService.deleteItem(itemId, type);
              // 2. Delete the report
              await _dismissReport(reportId);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
