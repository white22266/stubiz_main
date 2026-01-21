import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import 'warning_detail_page.dart';

class WarningsPage extends StatelessWidget {
  const WarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Warnings'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('warnings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final warnings = snapshot.data?.docs ?? [];

          if (warnings.isEmpty) {
            return const EmptyState(
              title: 'No Warnings',
              message: 'You have no warnings. Keep up the good work!',
              icon: Icons.check_circle_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: warnings.length,
            itemBuilder: (context, index) {
              final data = warnings[index].data() as Map<String, dynamic>;
              final warningId = warnings[index].id;
              final status = data['status'] ?? 'pending';
              final itemName = data['itemName'] ?? 'Unknown Item';
              final reason = data['reason'] ?? 'No reason provided';
              final createdAt = data['createdAt'] as Timestamp?;

              return Card(
                color: status == 'pending' ? Colors.orange.shade50 : Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    status == 'pending' ? Icons.warning : Icons.check_circle,
                    color: status == 'pending' ? Colors.orange : Colors.green,
                    size: 32,
                  ),
                  title: Text(
                    itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Reason: $reason'),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${status.toUpperCase()}',
                        style: TextStyle(
                          color: status == 'pending' ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatTimestamp(createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WarningDetailPage(
                          warningId: warningId,
                          warningData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
