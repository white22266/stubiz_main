import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/empty_state.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isActive': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const EmptyState(
              title: 'No Users',
              message: 'No registered users found.',
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final uid = users[index].id;
              final isActive = data['isActive'] == true;
              final role = data['role'] ?? 'student';
              final email = data['email'] ?? 'No Email';
              final name = data['displayName'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.red,
                    child: Icon(
                      isActive ? Icons.check : Icons.block,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$email\nRole: $role'),
                  isThreeLine: true,
                  trailing: role == 'admin'
                      ? const Chip(label: Text('Admin'))
                      : Switch(
                          value: isActive,
                          activeThumbColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (val) => _toggleUserStatus(uid, isActive),
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
