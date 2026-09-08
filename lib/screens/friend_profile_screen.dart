import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/social_link.dart';
import '../widgets/bottom_nav_bar.dart';

class FriendProfileScreen extends StatefulWidget {
  final String userId;
  final String fullName;
  final String roleType;
  final String avatarUrl;

  const FriendProfileScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.roleType,
    required this.avatarUrl,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> profiles = [
    {
      'bg': const Color(0xFFC8F331),
      'text': const Color(0xFF101112),
      'sub': const Color(0xFF101112).withValues(alpha: 0.7),
      'border': const Color(0xFFB8E321),
      'theme': 'neon',
    },
    {
      'bg': Colors.white,
      'text': const Color(0xFF101112),
      'sub': const Color(0xFF9A9EA6),
      'border': Colors.grey.shade100,
      'theme': 'light',
    },
    {
      'bg': const Color(0xFF101112),
      'text': Colors.white,
      'sub': Colors.grey.shade400,
      'border': Colors.grey.shade800,
      'theme': 'dark',
    },
  ];

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isDragging = false;
  int _connectedCount = 0;

  late final Stream<QuerySnapshot> _socialLinksStream;

  @override
  void initState() {
    super.initState();
    _socialLinksStream = FirebaseFirestore.instance
        .collection('social_links')
        .where('user_id', isEqualTo: widget.userId)
        .snapshots();

    _loadConnectedCount();
  }

  void _loadConnectedCount() {
    FirebaseFirestore.instance
        .collection('connection_requests')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      final count = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['sender_id'] == widget.userId ||
            data['receiver_id'] == widget.userId;
      }).length;

      if (mounted) {
        setState(() {
          _connectedCount = count;
        });
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 500;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    if (_dragOffset.distance > 90 ||
        details.velocity.pixelsPerSecond.distance > 300) {
      setState(() {
        _dragOffset = Offset(_dragOffset.dx.sign * 500, _dragOffset.dy);
      });

      Future.delayed(const Duration(milliseconds: 250), () {
        _swipeCard();
        setState(() {
          _dragOffset = Offset.zero;
          _dragAngle = 0.0;
        });
      });
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
      });
    }
  }

  void _swipeCard() {
    setState(() {
      var frontCard = profiles.removeAt(0);
      profiles.add(frontCard);
    });
  }

  void _bringCardToFront(int index) {
    setState(() {
      var tappedCard = profiles.removeAt(index);
      profiles.insert(0, tappedCard);
    });
  }

  void _showActiveLinksModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0xFF101112).withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: animation,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 360),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Active Links',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 24),
                              Flexible(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('social_links')
                                      .where('user_id', isEqualTo: widget.userId)
                                      .where('is_active', isEqualTo: true)
                                      .orderBy('sort_order')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    final docs = snapshot.data!.docs;
                                    if (docs.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          'No active links found.',
                                          style: TextStyle(
                                              color: Color(0xFF9A9EA6)),
                                        ),
                                      );
                                    }
                                    return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children: docs.map((doc) {
                                          final link = SocialLink.fromMap(
                                              doc.data() as Map<String, dynamic>,
                                              doc.id);
                                          return _buildModalLinkItem(link);
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -60,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: const Icon(Icons.close,
                                  color: Color(0xFF101112), size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor";
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return const Color(0xFF101112);
    }
  }

  Color _getBrandColor(String name) {
    name = name.toLowerCase();
    if (name.contains('phone')) return const Color(0xFF34B7F1);
    if (name.contains('email')) return const Color(0xFFEA4335);
    if (name.contains('whatsapp')) return const Color(0xFF25D366);
    if (name.contains('facebook')) return const Color(0xFF1877F2);
    if (name.contains('instagram')) return const Color(0xFFE1306C);
    if (name.contains('twitter') || name == 'x') return const Color(0xFF000000);
    if (name.contains('snapchat')) return const Color(0xFFFFFC00);
    if (name.contains('tiktok')) return const Color(0xFF000000);
    if (name.contains('linkedin')) return const Color(0xFF0A66C2);
    if (name.contains('youtube')) return const Color(0xFFFF0000);
    if (name.contains('github')) return const Color(0xFF181717);
    if (name.contains('website') ||
        name.contains('site') ||
        name.contains('web')) {
      return const Color(0xFF4A5568);
    }
    return const Color(0xFF101112);
  }

  dynamic _getIconData(String name) {
    name = name.toLowerCase();
    if (name.contains('phone')) return FontAwesomeIcons.phone;
    if (name.contains('email')) return FontAwesomeIcons.envelope;
    if (name.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (name.contains('facebook')) return FontAwesomeIcons.facebookF;
    if (name.contains('instagram')) return FontAwesomeIcons.instagram;
    if (name.contains('twitter') || name == 'x') return FontAwesomeIcons.xTwitter;
    if (name.contains('snapchat')) return FontAwesomeIcons.snapchat;
    if (name.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (name.contains('linkedin')) return FontAwesomeIcons.linkedinIn;
    if (name.contains('youtube')) return FontAwesomeIcons.youtube;
    if (name.contains('github')) return FontAwesomeIcons.github;
    if (name.contains('website') ||
        name.contains('site') ||
        name.contains('web')) {
      return FontAwesomeIcons.globe;
    }
    return FontAwesomeIcons.link;
  }

  Widget _buildSocialIcon({
    required String? iconUrl,
    required String platformName,
    required Color bgColor,
    required Color textColor,
    double size = 40,
    double iconSize = 16,
  }) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: iconUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: bgColor,
            child: const Center(
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: bgColor,
            child: Center(
                child: FaIcon(_getIconData(platformName),
                    color: textColor, size: iconSize)),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
          child: FaIcon(_getIconData(platformName),
              color: textColor, size: iconSize)),
    );
  }

  Widget _buildModalLinkItem(SocialLink link) {
    Color iconColor = _getColorFromHex(link.bgColor);
    Color textColor = _getColorFromHex(link.textColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Center(
              child: _buildSocialIcon(
                iconUrl: link.iconUrl,
                platformName: link.platformName,
                bgColor: iconColor,
                textColor: textColor,
                size: 40,
                iconSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          link.platformName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF101112),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          link.username,
                          style: const TextStyle(
                            color: Color(0xFF9A9EA6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_outward,
                          color: Colors.white, size: 11),
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

  Widget _socialCircle(Color color,
      {Widget? iconWidget,
        Widget? child,
        bool isText = false,
        String text = ''}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: isText
            ? Text(text,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF101112)))
            : (child ?? iconWidget),
      ),
    );
  }

  Widget _buildTopButton(Widget iconWidget, {Offset offset = Offset.zero}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
          child: Transform.translate(offset: offset, child: iconWidget)),
    );
  }

  Widget _buildProfileCard(
      Map<String, dynamic> data, {
        required String avatarUrl,
        required String fullName,
        required String roleType,
        required int connectedCount,
      }) {
    bool isDark = data['theme'] == 'dark';
    bool isNeon = data['theme'] == 'neon';

    Color dividerColor = isDark
        ? Colors.grey.shade800
        : (isNeon
        ? const Color(0xFF101112).withValues(alpha: 0.1)
        : Colors.grey.shade100);

    return Container(
      height: 260,
      width: MediaQuery.of(context).size.width - 40,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: data['bg'],
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: data['border']),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Developer',
                          style: TextStyle(
                              color: data['text'],
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text('profile',
                          style:
                          TextStyle(color: data['sub'], fontSize: 13)),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$connectedCount',
                          style: TextStyle(
                              color: data['text'],
                              fontWeight: FontWeight.bold,
                              fontSize: 24)),
                      Text('Connected',
                          style:
                          TextStyle(color: data['sub'], fontSize: 13)),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(avatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            fullName,
            style: TextStyle(
                color: data['text'],
                fontSize: 22,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            roleType,
            style: TextStyle(color: data['sub'], fontSize: 12.5),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Links',
                  style: TextStyle(
                      color: data['text'],
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Icon(CupertinoIcons.info_circle,
                      color: data['text'], size: 20),
                  const SizedBox(width: 6),
                  Text('Direct',
                      style: TextStyle(
                          color: data['text'],
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                      isDark ? Colors.white24 : const Color(0xFF101112),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFC8F331)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.avatarUrl.isNotEmpty
        ? widget.avatarUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.fullName)}&color=101112&background=C8F331';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: _buildTopButton(
                            const Icon(Icons.arrow_back_ios_new,
                                size: 18, color: Color(0xFF101112)),
                          ),
                        ),
                        Text(
                          widget.fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF101112),
                          ),
                        ),
                        _buildTopButton(
                          const FaIcon(FontAwesomeIcons.paperPlane,
                              size: 18, color: Color(0xFF101112)),
                          offset: const Offset(-1, 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // Profile Cards
                    SizedBox(
                      height: 290,
                      child: Stack(
                        alignment: Alignment.center,
                        children: profiles.asMap().entries.map((entry) {
                          int index = entry.key;
                          var cardData = entry.value;
                          bool isFront = index == 0;

                          double topOffset = index * 14.0;
                          double tiltAngle = index * 0.04;
                          double scale = 1.0 - (index * 0.02);

                          return AnimatedContainer(
                            key: ValueKey(cardData['theme']),
                            duration: isFront && _isDragging
                                ? Duration.zero
                                : const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            alignment: FractionalOffset.center,
                            transformAlignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translate(
                                isFront ? _dragOffset.dx : 0.0,
                                isFront ? _dragOffset.dy : topOffset,
                              )
                              ..rotateZ(isFront ? _dragAngle : tiltAngle)
                              ..scale(scale),
                            child: GestureDetector(
                              onTap: isFront
                                  ? null
                                  : () => _bringCardToFront(index),
                              onPanStart: isFront ? _onPanStart : null,
                              onPanUpdate: isFront ? _onPanUpdate : null,
                              onPanEnd: isFront ? _onPanEnd : null,
                              child: _buildProfileCard(
                                cardData,
                                avatarUrl: avatarUrl,
                                fullName: widget.fullName,
                                roleType: widget.roleType.isNotEmpty
                                    ? widget.roleType
                                    : 'No bio yet',
                                connectedCount: _connectedCount,
                              ),
                            ),
                          );
                        }).toList().reversed.toList(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ========== Search Section (زي الـ Home) ==========
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Search',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF101112))),
                            SizedBox(height: 2),
                            Text('Find new friends and explore profiles',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9A9EA6))),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: const Center(
                              child: Icon(Icons.add,
                                  color: Color(0xFF101112), size: 20)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ========== Active Links + Recent Connected ==========
                    SizedBox(
                      height: 216,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showActiveLinksModal,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: Colors.grey.shade100),
                                      ),
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: _socialLinksStream,
                                        builder: (context, snapshot) {
                                          int count = 0;
                                          List<Widget> icons = [];

                                          if (snapshot.hasData &&
                                              !snapshot.hasError) {
                                            var allDocs = snapshot.data!.docs
                                                .map((doc) => doc.data()
                                            as Map<String, dynamic>)
                                                .toList();
                                            var activeDocs = allDocs
                                                .where((doc) =>
                                            doc['is_active'] == true)
                                                .toList();
                                            activeDocs.sort((a, b) =>
                                                (a['sort_order'] ?? 0)
                                                    .compareTo(
                                                    b['sort_order'] ?? 0));

                                            count = activeDocs.length;
                                            var displayDocs =
                                            activeDocs.take(4).toList();

                                            for (int i = 0;
                                            i < displayDocs.length;
                                            i++) {
                                              var data = displayDocs[i];
                                              String platform =
                                                  data['platform_name'] ??
                                                      data['platform'] ??
                                                      '';
                                              String hexColor =
                                                  data['bg_color'] ?? '';
                                              String? iconUrl =
                                              data['icon_url'];

                                              Color bgColor = hexColor
                                                  .isNotEmpty
                                                  ? _getColorFromHex(hexColor)
                                                  : _getBrandColor(platform);
                                              Color textColor = (data[
                                              'text_color'] !=
                                                  null &&
                                                  data['text_color']
                                                      .toString()
                                                      .isNotEmpty)
                                                  ? _getColorFromHex(
                                                  data['text_color'])
                                                  : (platform
                                                  .toLowerCase()
                                                  .contains('snapchat')
                                                  ? Colors.black
                                                  : Colors.white);

                                              icons.add(Positioned(
                                                left: i * 18.0,
                                                child: _socialCircle(
                                                  bgColor,
                                                  child: _buildSocialIcon(
                                                    iconUrl: iconUrl,
                                                    platformName: platform,
                                                    bgColor: bgColor,
                                                    textColor: textColor,
                                                    size: 26,
                                                    iconSize: 12,
                                                  ),
                                                ),
                                              ));
                                            }
                                            if (count > 4) {
                                              icons.add(Positioned(
                                                left: 4 * 18.0,
                                                child: _socialCircle(
                                                  Colors.grey.shade100,
                                                  isText: true,
                                                  text: '+${count - 4}',
                                                ),
                                              ));
                                            }
                                          }

                                          return Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                height: 30,
                                                child: Stack(
                                                  children: icons.isEmpty
                                                      ? [
                                                    Positioned(
                                                      left: 0,
                                                      child: _socialCircle(
                                                        Colors
                                                            .grey.shade300,
                                                        iconWidget:
                                                        const FaIcon(
                                                          FontAwesomeIcons
                                                              .link,
                                                          color: Colors
                                                              .white,
                                                          size: 13,
                                                        ),
                                                      ),
                                                    )
                                                  ]
                                                      : icons,
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    count < 10
                                                        ? '0$count'
                                                        : '$count',
                                                    style: const TextStyle(
                                                      fontSize: 30,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      color: Color(0xFF101112),
                                                      height: 1,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const Text(
                                                    'Active social links',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF9A9EA6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC8F331),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(FontAwesomeIcons.userGroup,
                                          size: 15, color: Color(0xFF101112)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Friends',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Color(0xFF101112),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ========== Recent Connected (بتاعة الصديق) ==========
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border:
                                Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent connected',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF101112),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('connection_requests')
                                          .where('status',
                                          isEqualTo: 'accepted')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          );
                                        }

                                        final connections =
                                        snapshot.data!.docs.where((doc) {
                                          final data = doc.data()
                                          as Map<String, dynamic>;
                                          return data['sender_id'] ==
                                              widget.userId ||
                                              data['receiver_id'] ==
                                                  widget.userId;
                                        }).toList();

                                        if (connections.isEmpty) {
                                          return Opacity(
                                            opacity: 0.6,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: const [
                                                  FaIcon(
                                                    FontAwesomeIcons
                                                        .usersSlash,
                                                    color: Color(0xFF9A9EA6),
                                                    size: 22,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'No profiles yet',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                      Color(0xFF9A9EA6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        final recent =
                                        connections.take(4).toList();

                                        return ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: recent.length,
                                          itemBuilder: (context, index) {
                                            final data = recent[index].data()
                                            as Map<String, dynamic>;
                                            final friendId = data[
                                            'sender_id'] ==
                                                widget.userId
                                                ? data['receiver_id']
                                                : data['sender_id'];

                                            return FutureBuilder<
                                                DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(friendId)
                                                  .get(),
                                              builder: (context, userSnap) {
                                                if (!userSnap.hasData ||
                                                    !userSnap.data!.exists) {
                                                  return const SizedBox
                                                      .shrink();
                                                }

                                                final userData = userSnap
                                                    .data!
                                                    .data()
                                                as Map<String, dynamic>;
                                                final name = userData[
                                                'full_name'] ??
                                                    'User';
                                                final role = userData[
                                                'role_type'] ??
                                                    '';
                                                final avatar = userData[
                                                'avatar_url'] ??
                                                    '';

                                                return Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      bottom: 10),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration:
                                                        BoxDecoration(
                                                          shape: BoxShape
                                                              .circle,
                                                          border: Border.all(
                                                              color: Colors
                                                                  .grey
                                                                  .shade200),
                                                          image:
                                                          DecorationImage(
                                                            image: avatar
                                                                .isNotEmpty
                                                                ? NetworkImage(
                                                                avatar)
                                                                : NetworkImage(
                                                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&color=101112&background=C8F331'),
                                                            fit: BoxFit
                                                                .cover,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                                color: Color(
                                                                    0xFF101112),
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                            ),
                                                            if (role
                                                                .isNotEmpty)
                                                              Text(
                                                                role,
                                                                style:
                                                                const TextStyle(
                                                                  fontSize:
                                                                  10,
                                                                  color: Color(
                                                                      0xFF9A9EA6),
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
          const BottomNavBar(currentIndex: -1),
        ],
      ),
    );
  }
}