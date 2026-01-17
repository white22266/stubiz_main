// lib/screens/chat/chat_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'chat_room.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamChats(String myUid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  String _initialLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  String _safeOtherName(Map<String, dynamic> data, String otherUid) {
    final namesMap = (data['participantNames'] is Map)
        ? Map<String, dynamic>.from(data['participantNames'] as Map)
        : <String, dynamic>{};

    final otherName = (namesMap[otherUid] ?? '').toString().trim();
    return otherName.isNotEmpty ? otherName : 'Student User';
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamChats(me.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Failed to load chats: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();

              final participants = (data['participants'] is List)
                  ? (data['participants'] as List)
                        .map((e) => e.toString())
                        .toList()
                  : <String>[];

              final otherUid = participants.firstWhere(
                (id) => id != me.uid,
                orElse: () => '',
              );

              // Guard invalid chat docs
              if (otherUid.isEmpty) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.error_outline)),
                  title: const Text('Invalid chat'),
                  subtitle: const Text('Missing participants'),
                );
              }

              final otherName = _safeOtherName(data, otherUid);

              final lastMessage = (data['lastMessage'] ?? '').toString().trim();
              final subtitle = lastMessage.isEmpty
                  ? 'No messages yet'
                  : lastMessage;

              final ts = data['lastMessageAt'];
              String timeText = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                timeText =
                    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return ListTile(
                leading: CircleAvatar(child: Text(_initialLetter(otherName))),
                title: Text(otherName),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: timeText.isEmpty
                    ? null
                    : Text(
                        timeText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoom(
                        chatId: doc.id,
                        otherUid: otherUid,
                        otherName: otherName,
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
