import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Start Chat (Ensures unique chat ID between two users)
  static Future<String> startChat(
    String otherUserId,
    String otherUserName,
  ) async {
    final currentUserId = _auth.currentUser!.uid;
    final List<String> ids = [currentUserId, otherUserId]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final chatDoc = await _db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await _db.collection('chats').doc(chatId).set({
        'participants': ids,
        'names': {
          currentUserId: _auth.currentUser!.displayName ?? 'Me',
          otherUserId: otherUserName,
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  // 2. Send Message (Text or Image)
  static Future<void> sendMessage(
    String chatId,
    String text, {
    File? imageFile,
  }) async {
    final user = _auth.currentUser!;
    String? imageUrl;

    if (imageFile != null) {
      final ref = _storage.ref().child(
        'chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final messageData = {
      'senderId': user.uid,
      'senderName': user.displayName,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Update Chat Preview
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': imageFile != null ? '[Image]' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // 3. Streams
  static Stream<QuerySnapshot> getChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _auth.currentUser!.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
