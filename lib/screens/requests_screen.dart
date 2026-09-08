import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/connection_request.dart';
import '../models/profile.dart';
import '../widgets/bottom_nav_bar.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('connection_requests')
        .doc(requestId)
        .update({'status': newStatus});
  }

  void _openProfile(Profile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  image: DecorationImage(
                    image: profile.avatarUrl.isNotEmpty
                        ? NetworkImage(profile.avatarUrl)
                        : const NetworkImage(
                        'https://ui-avatars.com/api/?name=User&color=101112&background=C8F331'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101112),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.roleType.isNotEmpty ? profile.roleType : 'No bio yet',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9A9EA6),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F331),
                    foregroundColor: const Color(0xFF101112),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
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
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Color(0xFF101112),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Requests',
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: Color(0xFF101112),
                            ),
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC8F331),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('connection_requests')
                        .where('receiver_id', isEqualTo: _currentUserId)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final requests = snapshot.hasData
                          ? snapshot.data!.docs
                          .map((doc) => ConnectionRequest.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ))
                          .toList()
                          : [];

                      return Column(
                        children: [
                          // Title + Count
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pending Connections',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF101112),
                                  ),
                                ),
                                Text(
                                  '${requests.length} new',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9A9EA6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Empty State
                          if (requests.isEmpty)
                            Expanded(
                              child: Center(
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
                                            Icons.coffee_rounded,
                                            size: 32,
                                            color: Color(0xFF9A9EA6),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        "You're all caught up!",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF101112),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No new connection requests\nat the moment.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF9A9EA6),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  final req = requests[index];

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(req.senderId)
                                        .get(),
                                    builder: (context, userSnap) {
                                      if (!userSnap.hasData || !userSnap.data!.exists) {
                                        return const SizedBox.shrink();
                                      }

                                      final profile = Profile.fromMap(
                                        userSnap.data!.data() as Map<String, dynamic>,
                                        userSnap.data!.id,
                                      );

                                      return GestureDetector(
                                        onTap: () => _openProfile(profile),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.grey.shade100),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  // Avatar
                                                  Container(
                                                    width: 54,
                                                    height: 54,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.grey.shade200,
                                                        width: 1.5,
                                                      ),
                                                      image: DecorationImage(
                                                        image: profile.avatarUrl.isNotEmpty
                                                            ? NetworkImage(profile.avatarUrl)
                                                            : const NetworkImage(
                                                            'https://ui-avatars.com/api/?name=User&color=101112&background=C8F331'),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),

                                                  // Name + Text
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
                                                          'Wants to connect with you',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Color(0xFF9A9EA6),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 16),

                                              // Action Buttons
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () => _updateRequestStatus(req.id, 'rejected'),
                                                      child: Container(
                                                        height: 46,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF4F5F7),
                                                          borderRadius: BorderRadius.circular(22),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w700,
                                                              color: Color(0xFF101112),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () => _updateRequestStatus(req.id, 'accepted'),
                                                      child: Container(
                                                        height: 46,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFC8F331),
                                                          borderRadius: BorderRadius.circular(22),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'Confirm',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w700,
                                                              color: Color(0xFF101112)  ,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation
          const BottomNavBar(currentIndex: 3),
        ],
      ),
    );
  }
}