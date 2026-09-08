import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile.dart';
import '../widgets/bottom_nav_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Profile> _searchResults = [];
  bool _isSearching = false;

  // Map to track request status for each user
  // key = userId, value = 'none' | 'pending' | 'accepted'
  Map<String, String> _requestStatus = {};

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _requestStatus = {};
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('full_name', isGreaterThanOrEqualTo: query)
        .where('full_name', isLessThan: '$query\uf8ff')
        .limit(20)
        .get();

    final results = snapshot.docs
        .map((doc) => Profile.fromMap(doc.data(), doc.id))
        .where((p) => p.userId != currentUserId)
        .toList();

    // Load request statuses for these users
    final statusMap = <String, String>{};

    for (var profile in results) {
      statusMap[profile.userId] = await _getRequestStatus(profile.userId);
    }

    setState(() {
      _searchResults = results;
      _requestStatus = statusMap;
      _isSearching = false;
    });
  }

  Future<String> _getRequestStatus(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return 'none';

    // Check if I sent a request
    final sent = await FirebaseFirestore.instance
        .collection('connection_requests')
        .where('sender_id', isEqualTo: currentUserId)
        .where('receiver_id', isEqualTo: otherUserId)
        .get();

    if (sent.docs.isNotEmpty) {
      final status = sent.docs.first.data()['status'] as String? ?? 'pending';
      return status; // pending or accepted
    }

    // Check if they sent me a request
    final received = await FirebaseFirestore.instance
        .collection('connection_requests')
        .where('sender_id', isEqualTo: otherUserId)
        .where('receiver_id', isEqualTo: currentUserId)
        .get();

    if (received.docs.isNotEmpty) {
      final status = received.docs.first.data()['status'] as String? ?? 'pending';
      return status;
    }

    return 'none';
  }

  Future<void> _sendRequest(String receiverId) async {
    final senderId = FirebaseAuth.instance.currentUser?.uid;
    if (senderId == null) return;

    await FirebaseFirestore.instance.collection('connection_requests').add({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _requestStatus[receiverId] = 'pending';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection request sent!'),
          backgroundColor: Color(0xFFC8F331),
        ),
      );
    }
  }

  Future<void> _cancelRequest(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Delete the request I sent
    final sent = await FirebaseFirestore.instance
        .collection('connection_requests')
        .where('sender_id', isEqualTo: currentUserId)
        .where('receiver_id', isEqualTo: otherUserId)
        .get();

    for (var doc in sent.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _requestStatus[otherUserId] = 'none';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _openProfile(Profile profile) {
    // TODO: Replace with your actual Profile View screen when ready
    // For now showing a simple bottom sheet with info
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
                profile.roleType,
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

  Widget _buildActionButton(String userId) {
    final status = _requestStatus[userId] ?? 'none';

    if (status == 'pending') {
      // Request already sent → show cancel icon
      return GestureDetector(
        onTap: () => _cancelRequest(userId),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red.shade100),
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.redAccent,
            ),
          ),
        ),
      );
    }

    if (status == 'accepted') {
      // Already connected
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green.shade100),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 20,
            color: Colors.green,
          ),
        ),
      );
    }

    // No request yet → Add button
    return GestureDetector(
      onTap: () => _sendRequest(userId),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Center(
          child: Icon(
            Icons.person_add_alt_1,
            size: 20,
            color: Color(0xFF101112),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        'Search',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101112),
                        ),
                      ),
                      const SizedBox(width: 46),
                    ],
                  ),
                ),

                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: Color(0xFF9A9EA6), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchUsers,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101112),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search by name...',
                              hintStyle: TextStyle(
                                color: Color(0xFF9A9EA6),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.close, size: 20, color: Color(0xFF9A9EA6)),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _searchUsers(_searchController.text),
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC8F331),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: Color(0xFF101112),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Results
                if (_isSearching)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
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
                                  Icons.sentiment_dissatisfied_rounded,
                                  size: 32,
                                  color: Color(0xFF9A9EA6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No profiles found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF101112),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try searching with a different\nname or spelling.',
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
                else if (_searchResults.isNotEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Results for "${_searchController.text}"',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF101112),
                                  ),
                                ),
                                Text(
                                  '${_searchResults.length} found',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9A9EA6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final profile = _searchResults[index];

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
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.grey.shade200, width: 1.5),
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

                                        // Name + Role
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
                                              Text(
                                                profile.roleType.isNotEmpty
                                                    ? profile.roleType
                                                    : 'No bio yet',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF9A9EA6)  ,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // Action Button (Add / Cancel / Connected)
                                        _buildActionButton(profile.userId),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
              ],
            ),
          ),

          // Bottom Navigation
          const BottomNavBar(currentIndex: -1),
        ],
      ),
    );
  }
}