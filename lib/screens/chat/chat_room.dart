// lib/screens/chat/chat_room.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ChatRoom extends StatefulWidget {
  final String chatId;
  final String otherUid;
  final String otherName;

  const ChatRoom({
    super.key,
    required this.chatId,
    required this.otherUid,
    required this.otherName,
  });

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

  CollectionReference<Map<String, dynamic>> get _msgRef =>
      _chatRef.collection('messages');

  @override
  void initState() {
    super.initState();
    _ensureChatExists();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getMyName() async {
    final me = AuthService.currentUser;
    if (me == null) return 'Student';

    final authName = (me.displayName ?? '').trim();
    if (authName.isNotEmpty) return authName;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .get();
    final name = (snap.data()?['displayName'] ?? '').toString().trim();
    return name.isNotEmpty ? name : me.uid;
  }

  Future<void> _ensureChatExists() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final myName = await _getMyName();

    final participants = [me.uid, widget.otherUid]..sort();

    await _chatRef.set({
      'participants': participants,
      'participantNames': {me.uid: myName, widget.otherUid: widget.otherName},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamMessages() {
    return _msgRef.orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> _sendMessage() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      await _ensureChatExists();
      final myName = await _getMyName();

      await _msgRef.add({
        'type': 'text',
        'senderId': me.uid,
        'senderName': myName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _chatRef.set({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'participantNames': {me.uid: myName, widget.otherUid: widget.otherName},
      }, SetOptions(merge: true));

      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ====== Public helper (call from ExchangeDetail / Marketplace) ======
  // Sends an "exchange request card" message into the chat (Shopee-style).
  static Future<void> sendExchangeRequestMessage({
    required String chatId,
    required String requesterId,
    required String requesterName,
    required String ownerId,
    required String ownerName,
    required String exchangeId,
    required String postId,
    required String postTitle,
    required String? postThumbnailUrl,
    required String wantedItem,
    required String category,
  }) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages');

    final participants = [requesterId, ownerId]..sort();

    await chatRef.set({
      'participants': participants,
      'participantNames': {requesterId: requesterName, ownerId: ownerName},
      'lastMessage': 'Exchange request: $postTitle',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await msgRef.add({
      'type': 'exchange_request',
      'senderId': requesterId,
      'senderName': requesterName,
      'createdAt': FieldValue.serverTimestamp(),
      'exchangeId': exchangeId,
      'postId': postId,
      'postTitle': postTitle,
      'postThumbnailUrl': postThumbnailUrl ?? '',
      'wantedItem': wantedItem,
      'category': category,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': 'pending',
    });
  }

  Future<void> _ownerDecideExchange({
    required String exchangeId,
    required String newStatus, // accepted / rejected
    required Map<String, dynamic> cardData,
  }) async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final ownerId = (cardData['ownerId'] ?? '').toString();
    if (me.uid != ownerId) return;

    try {
      final exRef = FirebaseFirestore.instance
          .collection('exchanges')
          .doc(exchangeId);

      await exRef.set({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': me.uid,
      }, SetOptions(merge: true));

      final myName = await _getMyName();
      final postTitle = (cardData['postTitle'] ?? '').toString();

      await _msgRef.add({
        'type': 'exchange_status',
        'senderId': me.uid,
        'senderName': myName,
        'text': newStatus == 'accepted'
            ? 'Accepted exchange request: $postTitle'
            : 'Rejected exchange request: $postTitle',
        'createdAt': FieldValue.serverTimestamp(),
        'exchangeId': exchangeId,
        'status': newStatus,
      });

      await _chatRef.set({
        'lastMessage': newStatus == 'accepted'
            ? 'Accepted request'
            : 'Rejected request',
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update exchange failed: $e')));
    }
  }

  Future<String> _exchangeStatus(String exchangeId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('exchanges')
          .doc(exchangeId)
          .get();
      if (!snap.exists) return 'pending';
      return (snap.data()?['status'] ?? 'pending').toString();
    } catch (_) {
      return 'pending';
    }
  }

  Future<void> _openReportDialog() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final detailCtrl = TextEditingController();
    String reason = 'Harassment';
    bool saving = false;
    String err = '';

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            return AlertDialog(
              title: const Text('Report'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    items: const [
                      DropdownMenuItem(
                        value: 'Harassment',
                        child: Text('Harassment'),
                      ),
                      DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                      DropdownMenuItem(value: 'Scam', child: Text('Scam')),
                      DropdownMenuItem(
                        value: 'Inappropriate Content',
                        child: Text('Inappropriate Content'),
                      ),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v == null) return;
                            setStateDialog(() => reason = v);
                          },
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (err.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(err, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setStateDialog(() {
                            saving = true;
                            err = '';
                          });

                          try {
                            final myName = await _getMyName();
                            final ref = FirebaseFirestore.instance
                                .collection('reports')
                                .doc();

                            final reportId =
                                'R${ref.id.substring(0, 6).toUpperCase()}';
                            final title = 'Chat Report: ${widget.otherName}';
                            final details = [
                              'Reason: $reason',
                              if (detailCtrl.text.trim().isNotEmpty)
                                'Details: ${detailCtrl.text.trim()}',
                              'ChatId: ${widget.chatId}',
                              'ReportedUserId: ${widget.otherUid}',
                              'ReportedUserName: ${widget.otherName}',
                              'ReporterId: ${me.uid}',
                              'ReporterName: $myName',
                            ].join('\n');

                            await ref.set({
                              'reportId': reportId,
                              'title': title,
                              'details': details,
                              'status': 'Pending',
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                              'reporterId': me.uid,
                              'reporterName': myName,
                              'targetType': 'chat',
                              'targetId': widget.chatId,
                              'reportedUserId': widget.otherUid,
                              'reportedUserName': widget.otherName,
                            });

                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Report submitted. Admin will review it.',
                                ),
                              ),
                            );
                          } catch (e) {
                            setStateDialog(() => err = e.toString());
                          } finally {
                            setStateDialog(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    detailCtrl.dispose();
  }

  Widget _buildExchangeCard(Map<String, dynamic> d, bool isMe) {
    final exchangeId = (d['exchangeId'] ?? '').toString();
    final postTitle = (d['postTitle'] ?? '').toString();
    final wantedItem = (d['wantedItem'] ?? '').toString();
    final category = (d['category'] ?? '').toString();
    final thumb = (d['postThumbnailUrl'] ?? '').toString();
    final requesterName = (d['requesterName'] ?? '').toString();
    final ownerId = (d['ownerId'] ?? '').toString();

    final me = AuthService.currentUser;
    final isOwner = me != null && me.uid == ownerId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.82,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exchange Request',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: thumb.isEmpty
                    ? const Icon(Icons.swap_horiz)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(thumb, fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(category),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text('Wants: $wantedItem'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Requested by $requesterName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FutureBuilder<String>(
            future: _exchangeStatus(exchangeId),
            builder: (context, snap) {
              final status =
                  (snap.data ?? (d['status'] ?? 'pending').toString())
                      .toString();

              final statusText = switch (status) {
                'accepted' => 'Status: Accepted',
                'rejected' => 'Status: Rejected',
                'cancelled' => 'Status: Cancelled',
                _ => 'Status: Pending',
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isOwner && status == 'pending') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _ownerDecideExchange(
                              exchangeId: exchangeId,
                              newStatus: 'rejected',
                              cardData: d,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _ownerDecideExchange(
                              exchangeId: exchangeId,
                              newStatus: 'accepted',
                              cardData: d,
                            ),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble({
    required bool isMe,
    required String senderName,
    required String text,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName.isNotEmpty)
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        actions: [
          IconButton(
            tooltip: 'Report',
            onPressed: _openReportDialog,
            icon: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _streamMessages(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Failed: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottomSoon(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data();
                    final type = (d['type'] ?? 'text').toString();

                    final senderId = (d['senderId'] ?? '').toString();
                    final senderName = (d['senderName'] ?? '').toString();
                    final isMe = me != null && senderId == me.uid;

                    if (type == 'exchange_request') {
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _buildExchangeCard(d, isMe),
                      );
                    }

                    final text = (d['text'] ?? '').toString();
                    return _buildTextBubble(
                      isMe: isMe,
                      senderName: senderName,
                      text: text,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _sending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
