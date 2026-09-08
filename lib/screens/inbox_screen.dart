import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile.dart';
import 'chat_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ===================== Header =====================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF101112)),
                          ),
                        ),
                      ),
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101112),
                        ),
                      ),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.edit_outlined, size: 20, color: Color(0xFF101112)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===================== Content =====================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('connection_requests')
                        .where('status', isEqualTo: 'accepted')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final connections = snapshot.hasData
                          ? snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['sender_id'] == _currentUserId ||
                            data['receiver_id'] == _currentUserId;
                      }).toList()
                          : [];

                      // ========== Empty State ==========
                      if (connections.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8E9EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 32,
                                      color: Color(0xFF9A9EA6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF101112),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Connect with people to start\nsending messages.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9A9EA6),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to SearchScreen
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC8F331),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Text(
                                      'Find People',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF101112),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // ========== Conversations List ==========
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                        itemCount: connections.length,
                        itemBuilder: (context, index) {
                          final data = connections[index].data() as Map<String, dynamic>;
                          final friendId = data['sender_id'] == _currentUserId
                              ? data['receiver_id']
                              : data['sender_id'];

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData || !userSnap.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final profile = Profile.fromMap(
                                userSnap.data!.data() as Map<String, dynamic>,
                                userSnap.data!.id,
                              );

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        receiverId: friendId,
                                        receiverName: profile.fullName,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar + Online Dot
                                      Stack(
                                        children: [
                                          Container(
                                            width: 54,
                                            height: 54,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                              image: DecorationImage(
                                                image: profile.avatarUrl.isNotEmpty
                                                    ? NetworkImage(profile.avatarUrl)
                                                    : const NetworkImage(
                                                    'https://ui-avatars.com/api/?name=User&color=101112&background=C8F331'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFC8F331),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      // Name + Last message placeholder
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.fullName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF101112),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            const Text(
                                              'Tap to open chat',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF9A9EA6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF4F5F7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: Color(0xFF101112),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation
          const BottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }
}