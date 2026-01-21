// lib/screens/exchange/exchange_detail.dart
import 'package:flutter/material.dart';
import '../../models/listing_item.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/marketplace_service.dart';
import '../chat/chat_room.dart';
import 'edit_exchange.dart';

class ExchangeDetail extends StatelessWidget {
  final ListingItem item;
  const ExchangeDetail({super.key, required this.item});

  Future<void> _startChat(BuildContext context) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }
    if (user.uid == item.ownerId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This is your own post')));
      return;
    }

    try {
      final chatId = await ChatService.startChat(item.ownerId, item.ownerName);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatId: chatId,
            otherUserId: item.ownerId,
            otherUserName: item.ownerName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editExchange(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditExchangeScreen(exchange: item),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteExchange(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exchange'),
        content: const Text(
          'Are you sure you want to delete this exchange post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await MarketplaceService.deleteItem(
          item.id,
          item.type,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exchange deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting exchange: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _reportItem(BuildContext context) {
    const reasons = <String>[
      'Scam / Fraud',
      'Prohibited Item',
      'Harassment',
      'Spam',
      'Other',
    ];

    String selected = reasons.first;
    final otherCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selected,
                  onChanged: (v) => setLocal(() => selected = v!),
                  title: Text(r),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (selected == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Write a short reason...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = selected == 'Other'
                    ? otherCtrl.text.trim()
                    : selected.trim();

                if (reason.isEmpty) return;

                await MarketplaceService.reportItem(
                  item.id,
                  item.type.value,
                  reason,
                );

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wanted = (item.wantedItem ?? item.wantedItem ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          if (AuthService.currentUser?.uid == item.ownerId) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editExchange(context),
              tooltip: 'Edit Exchange',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteExchange(context),
              tooltip: 'Delete Exchange',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: () => _reportItem(context),
              tooltip: 'Report',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              Image.network(
                item.imageUrl!,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 280,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (wanted.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_calls),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Wanted: $wanted',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(item.description),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.ownerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.category,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.timeAgo,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _startChat(context),
          icon: const Icon(Icons.chat),
          label: const Text('Chat to Swap'),
        ),
      ),
    );
  }
}
