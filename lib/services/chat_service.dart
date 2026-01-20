import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _me() => _auth.currentUser!.uid;

  // ---------- Helpers ----------
  // Source of truth: users/{uid}.displayName
  // Fallback: FirebaseAuth displayName
  // Final fallback: "Student"
  static Future<String> _getDisplayName(String uid) async {
    // 1) Firestore users collection
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final name = (doc.data()?['displayName'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    } catch (_) {}

    // 2) FirebaseAuth (only valid for current user)
    if (_auth.currentUser != null && _auth.currentUser!.uid == uid) {
      final authName = (_auth.currentUser!.displayName ?? '').toString().trim();
      if (authName.isNotEmpty) return authName;
    }

    return 'Student';
  }

  static Future<String> _myName() async => _getDisplayName(_me());

  // Ensure chat doc has names filled, so ChatList won't show Unknown.
  // - Merge names map
  // - Do not overwrite existing non-empty names
  static Future<void> _ensureChatNames(
    DocumentReference<Map<String, dynamic>> chatRef,
    String myUid,
    String otherUid, {
    String? otherNameHint,
  }) async {
    final snap = await chatRef.get();
    final data = snap.data() ?? {};

    final existingNames = (data['names'] is Map)
        ? Map<String, dynamic>.from(data['names'] as Map)
        : <String, dynamic>{};

    final myExisting = (existingNames[myUid] ?? '').toString().trim();
    final otherExisting = (existingNames[otherUid] ?? '').toString().trim();

    final myName = myExisting.isNotEmpty
        ? myExisting
        : await _getDisplayName(myUid);

    String otherName = otherExisting;
    if (otherName.isEmpty) {
      final hint = (otherNameHint ?? '').trim();
      if (hint.isNotEmpty) {
        otherName = hint;
      } else {
        otherName = await _getDisplayName(otherUid);
      }
    }

    await chatRef.set({
      'names': {myUid: myName, otherUid: otherName},
    }, SetOptions(merge: true));
  }

  // ---------- 1) Start Chat (unique chat id for 2 users) ----------
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
      final myName = await _myName();
      final otherName = otherUserName.trim().isNotEmpty
          ? otherUserName.trim()
          : await _getDisplayName(otherUserId);

      await ref.set({
        'participants': ids,
        'names': {myUid: myName, otherUserId: otherName},
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
      });
    } else {
      // Backfill names if old chat doc is missing/empty names
      await _ensureChatNames(
        ref,
        myUid,
        otherUserId,
        otherNameHint: otherUserName,
      );
    }

    return chatId;
  }

  // ---------- 2) Streams (typed) ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> getChats() {
    final myUid = _me();
    return _db
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
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

  // ---------- 3) Send Text ----------
  static Future<void> sendText(String chatId, String text) async {
    final user = _auth.currentUser!;
    final myUid = user.uid;
    final senderName = await _myName();

    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': myUid,
        'senderName': senderName, // <-- fixed
        'type': 'text',
        'text': text,
        'imageUrl': null,
        'createdAt': now,
        'readBy': [myUid],
      });

      tx.update(chatRef, {
        'lastMessage': text,
        'lastMessageType': 'text',
        'lastMessageAt': now,
        'lastSenderId': myUid,
        // Ensure my name in chat doc is not "Me"/empty
        'names.$myUid': senderName,
      });
    });
  }

  // ---------- 4) Send Image ----------
  static Future<void> sendImage(String chatId, File imageFile) async {
    final user = _auth.currentUser!;
    final myUid = user.uid;
    final senderName = await _myName();

    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final path = 'chat_images/$chatId/${msgRef.id}.jpg';
    final uploadTask = await _storage.ref(path).putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': myUid,
        'senderName': senderName, // <-- fixed
        'type': 'image',
        'text': null,
        'imageUrl': imageUrl,
        'createdAt': now,
        'readBy': [myUid],
      });

      tx.update(chatRef, {
        'lastMessage': '[Image]',
        'lastMessageType': 'image',
        'lastMessageAt': now,
        'lastSenderId': myUid,
        // Ensure my name in chat doc is not "Me"/empty
        'names.$myUid': senderName,
      });
    });
  }

  // ---------- 5) Mark read ----------
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
