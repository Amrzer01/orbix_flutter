import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final String _chatId;
  bool _isBlockedByMe = false;      // أنا اللي حاجز الطرف التاني
  bool _isBlockedByOther = false;   // الطرف التاني حاجزني
  bool _isLoadingBlockStatus = true;

  @override
  void initState() {
    super.initState();
    final ids = [_currentUserId, widget.receiverId]..sort();
    _chatId = ids.join('_');
    _checkBlockStatus();
  }

  // ===================== Check Block Status =====================
  Future<void> _checkBlockStatus() async {
    // هل أنا حاجز الطرف التاني؟
    final blockedByMe = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked')
        .doc(widget.receiverId)
        .get();

    // هل الطرف التاني حاجزني؟
    final blockedByOther = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .collection('blocked')
        .doc(_currentUserId)
        .get();

    if (mounted) {
      setState(() {
        _isBlockedByMe = blockedByMe.exists;
        _isBlockedByOther = blockedByOther.exists;
        _isLoadingBlockStatus = false;
      });
    }
  }

  // ===================== Send Text =====================
  Future<void> _sendMessage() async {
    if (_isBlockedByMe || _isBlockedByOther) return;

    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId.isEmpty) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'text': text,
      'type': 'text',
      'senderId': _currentUserId,
      'receiverId': widget.receiverId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
      'participants': [_currentUserId, widget.receiverId],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': _currentUserId,
    }, SetOptions(merge: true));
  }

  // ===================== Send Image =====================
  Future<void> _sendImage() async {
    if (_isBlockedByMe || _isBlockedByOther) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    final file = File(image.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('chat_images').child(_chatId).child(fileName);

    final uploadTask = await ref.putFile(file);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'text': '',
      'imageUrl': imageUrl,
      'type': 'image',
      'senderId': _currentUserId,
      'receiverId': widget.receiverId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
      'participants': [_currentUserId, widget.receiverId],
      'lastMessage': '📷 Photo',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': _currentUserId,
    }, SetOptions(merge: true));
  }

  // ===================== Delete Chat (For Me) =====================
  Future<void> _deleteChatForMe() async {
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
      'deletedFor': FieldValue.arrayUnion([_currentUserId]),
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted for you'), backgroundColor: Colors.orange),
      );
    }
  }

  // ===================== Block User =====================
  Future<void> _blockUser() async {
    // 1. Add to blocked list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked')
        .doc(widget.receiverId)
        .set({'blockedAt': FieldValue.serverTimestamp()});

    // 2. Remove the friendship (connection)
    final connections = await FirebaseFirestore.instance
        .collection('connection_requests')
        .where('status', isEqualTo: 'accepted')
        .get();

    for (var doc in connections.docs) {
      final data = doc.data();
      final isMatch = (data['sender_id'] == _currentUserId && data['receiver_id'] == widget.receiverId) ||
          (data['sender_id'] == widget.receiverId && data['receiver_id'] == _currentUserId);

      if (isMatch) {
        await doc.reference.delete(); // إلغاء الصداقة
      }
    }

    setState(() {
      _isBlockedByMe = true;
    });

    if (mounted) {
      Navigator.pop(context); // close menu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked & friendship removed'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.orange),
                title: const Text('Delete Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Only for you'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteChatForMe();
                },
              ),
              if (!_isBlockedByMe) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.redAccent),
                  title: const Text('Block User', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String status, bool isMe) {
    if (!isMe) return const SizedBox();

    if (status == 'seen') {
      return const FaIcon(FontAwesomeIcons.checkDouble, size: 11, color: Color(0xFF34B7F1));
    } else if (status == 'delivered') {
      return FaIcon(FontAwesomeIcons.checkDouble, size: 11, color: const Color(0xFF101112).withValues(alpha: 0.7));
    } else {
      return FaIcon(FontAwesomeIcons.check, size: 11, color: const Color(0xFF101112).withValues(alpha: 0.7));
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.receiverAvatar ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.receiverName)}&color=101112&background=C8F331';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // ===================== Header =====================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F5F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF101112)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(avatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.receiverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101112),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isBlockedByMe
                              ? 'Blocked'
                              : _isBlockedByOther
                              ? 'Unavailable'
                              : 'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isBlockedByMe || _isBlockedByOther
                                ? Colors.redAccent
                                : const Color(0xFFC8F331),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showMenu,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F5F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.more_vert, size: 22, color: Color(0xFF101112)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===================== Messages =====================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(_chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nSay hi! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF9A9EA6), fontSize: 15),
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  // Mark as seen
                  for (var doc in messages) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['receiverId'] == _currentUserId && data['status'] != 'seen') {
                      doc.reference.update({'status': 'seen'});
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == _currentUserId;
                      final type = data['type'] ?? 'text';
                      final status = data['status'] ?? 'sent';

                      String timeString = '';
                      if (data['createdAt'] != null) {
                        final date = (data['createdAt'] as Timestamp).toDate();
                        timeString =
                        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(avatarUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Container(
                                padding: type == 'image'
                                    ? const EdgeInsets.all(6)
                                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFFC8F331) : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                  border: isMe ? null : Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (type == 'image')
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: data['imageUrl'] ?? '',
                                          width: 220,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            width: 220,
                                            height: 180,
                                            color: Colors.grey.shade200,
                                            child: const Center(child: CircularProgressIndicator()),
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        data['text'] ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFF101112),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            color: const Color(0xFF101112).withValues(alpha: 0.6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 5),
                                          _buildStatusIcon(status, isMe),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ===================== Input OR Blocked Message =====================
            if (_isLoadingBlockStatus)
              const SizedBox(height: 70)
            else if (_isBlockedByOther)
            // الطرف التاني حاجزني
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                color: Colors.white,
                child: Text(
                  'You have been blocked by ${widget.receiverName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              )
            else if (_isBlockedByMe)
              // أنا اللي حاجز
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  color: Colors.white,
                  child: const Text(
                    'You blocked this user',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                )
              else
              // الإدخال العادي
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _sendImage,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F5F7),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.image, size: 18, color: Color(0xFF101112)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 46),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF101112),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message...',
                              hintStyle: TextStyle(color: Color(0xFF9A9EA6), fontSize: 15),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFF101112),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.paperPlane, size: 16, color: Color(0xFFC8F331)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}