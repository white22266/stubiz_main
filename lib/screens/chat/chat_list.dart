import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'chat_room.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _previewText(Map<String, dynamic> data) {
    final type = (data['lastMessageType'] ?? 'text').toString();
    final last = (data['lastMessage'] ?? '').toString();
    if (type == 'image') return '📷 Image';
    return last.isEmpty ? '—' : last;
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ChatService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final names = (data['names'] is Map)
                  ? Map<String, dynamic>.from(data['names'])
                  : <String, dynamic>{};

              // Find the other user
              String otherName = 'Unknown';
              String otherId = '';
              for (final entry in names.entries) {
                if (entry.key != me.uid) {
                  otherId = entry.key;
                  otherName = entry.value?.toString() ?? 'Unknown';
                  break;
                }
              }

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(otherName),
                subtitle: Text(
                  _previewText(data),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatId: docs[index].id,
                        otherUserId: otherId,
                        otherUserName: otherName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
