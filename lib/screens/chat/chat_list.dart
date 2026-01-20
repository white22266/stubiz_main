// lib/screens/chat/chat_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_room.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Cache to avoid fetching the same user's name repeatedly
  final Map<String, String> _nameCache = {};

  String _previewText(Map<String, dynamic> data) {
    final type = (data['lastMessageType'] ?? 'text').toString();
    final last = (data['lastMessage'] ?? '').toString();
    if (type == 'image') return '📷 Image';
    return last.isEmpty ? '—' : last;
  }

  Future<String> _fetchDisplayName(String uid) async {
    final cached = _nameCache[uid];
    if (cached != null && cached.trim().isNotEmpty) return cached;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final name = (doc.data()?['displayName'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        _nameCache[uid] = name;
        return name;
      }
    } catch (_) {}

    _nameCache[uid] = 'Unknown';
    return 'Unknown';
  }

  /// Extract other user id and name from a chat document.
  /// Priority:
  /// 1) names map (your current structure)
  /// 2) participants list to find otherId (if names missing)
  /// 3) fetch users/{otherId}.displayName as fallback (done later)
  ({String otherId, String otherName}) _resolveOtherUser(
    Map<String, dynamic> data,
    String myUid,
  ) {
    // 1) Try names map
    final names = (data['names'] is Map)
        ? Map<String, dynamic>.from(data['names'] as Map)
        : <String, dynamic>{};

    String otherId = '';
    String otherName = '';

    for (final entry in names.entries) {
      if (entry.key != myUid) {
        otherId = entry.key;
        otherName = (entry.value ?? '').toString().trim();
        break;
      }
    }

    // If name exists, cache it
    if (otherId.isNotEmpty && otherName.isNotEmpty) {
      _nameCache[otherId] = otherName;
      return (otherId: otherId, otherName: otherName);
    }

    // 2) Fallback: use participants to find otherId
    final participants = (data['participants'] is List)
        ? (data['participants'] as List).map((e) => e.toString()).toList()
        : <String>[];

    if (otherId.isEmpty && participants.isNotEmpty) {
      otherId = participants.firstWhere((id) => id != myUid, orElse: () => '');
    }

    // Still may not have name here; will fetch from users in UI builder
    return (otherId: otherId, otherName: otherName);
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
              final doc = docs[index];
              final data = doc.data();

              final resolved = _resolveOtherUser(data, me.uid);
              final otherId = resolved.otherId;
              final fromNames = resolved.otherName.trim();
              final preview = _previewText(data);

              // If we already have a good name in names map, use it immediately
              if (otherId.isNotEmpty &&
                  fromNames.isNotEmpty &&
                  fromNames != 'Unknown') {
                final otherName = fromNames;

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(otherName),
                  subtitle: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          chatId: doc.id,
                          otherUserId: otherId,
                          otherUserName: otherName,
                        ),
                      ),
                    );
                  },
                );
              }

              // Otherwise, fallback to users/{uid}.displayName (cached)
              return FutureBuilder<String>(
                future: otherId.isEmpty
                    ? Future.value('Unknown')
                    : _fetchDisplayName(otherId),
                builder: (context, nameSnap) {
                  final otherName = (nameSnap.data ?? 'Unknown').trim();
                  final shownName = otherName.isEmpty ? 'Unknown' : otherName;

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(shownName),
                    subtitle: Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            chatId: doc.id,
                            otherUserId: otherId,
                            otherUserName: shownName,
                          ),
                        ),
                      );
                    },
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
