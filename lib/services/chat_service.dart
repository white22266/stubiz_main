import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _me() => _auth.currentUser!.uid;

  // 1) Start Chat (unique chat id for 2 users)
  static Future<String> startChat(
    String otherUserId,
    String otherUserName,
  ) async {
    final myUid = _me();
    final ids = [myUid, otherUserId]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final ref = _db.collection('chats').doc(chatId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'participants': ids,
        'names': {
          myUid: _auth.currentUser!.displayName ?? 'Me',
          otherUserId: otherUserName,
        },
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
      });
    }

    return chatId;
  }

  // 2) Streams (typed)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getChats() {
    final myUid = _me();
    return _db
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String chatId,
  ) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 3) Send Text
  static Future<void> sendText(String chatId, String text) async {
    final user = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Me',
        'type': 'text',
        'text': text,
        'imageUrl': null,
        'createdAt': now,
        'readBy': [user.uid],
      });

      tx.update(chatRef, {
        'lastMessage': text,
        'lastMessageType': 'text',
        'lastMessageTime': now,
        'lastSenderId': user.uid,
      });
    });
  }

  // 4) Send Image
  static Future<void> sendImage(String chatId, File imageFile) async {
    final user = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final path = 'chat_images/$chatId/${msgRef.id}.jpg';
    final uploadTask = await _storage.ref(path).putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Me',
        'type': 'image',
        'text': null,
        'imageUrl': imageUrl,
        'createdAt': now,
        'readBy': [user.uid],
      });

      tx.update(chatRef, {
        'lastMessage': '[Image]',
        'lastMessageType': 'image',
        'lastMessageTime': now,
        'lastSenderId': user.uid,
      });
    });
  }

  // 5) Mark read (mark latest N messages as read by me)
  static Future<void> markChatRead(String chatId, {int limit = 50}) async {
    final myUid = _me();
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final batch = _db.batch();
    for (final d in snap.docs) {
      final data = d.data();
      final readBy = (data['readBy'] is List) ? List.from(data['readBy']) : [];
      if (!readBy.contains(myUid)) {
        batch.update(d.reference, {
          'readBy': FieldValue.arrayUnion([myUid]),
        });
      }
    }
    await batch.commit();
  }
}
