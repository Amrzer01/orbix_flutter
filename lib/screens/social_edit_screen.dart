import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/social_link.dart';

class SocialEditScreen extends StatefulWidget {
  const SocialEditScreen({super.key});

  @override
  State<SocialEditScreen> createState() => _SocialEditScreenState();
}

class _SocialEditScreenState extends State<SocialEditScreen> {
  bool _isLoading = true;
  List<SocialLink> _activeLinks = [];

  final Map<String, List<Map<String, dynamic>>> _categories = {
    'Contact & Utilities': [
      {'name': 'Phone', 'icon': FontAwesomeIcons.phone, 'color': const Color(0xFF34B7F1), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Email', 'icon': FontAwesomeIcons.solidEnvelope, 'color': const Color(0xFFEA4335), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Location (Map)', 'icon': FontAwesomeIcons.locationDot, 'color': const Color(0xFF34A853), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Website', 'icon': FontAwesomeIcons.globe, 'color': const Color(0xFF101112), 'textColor': const Color(0xFFFFFFFF)},
    ],
    'Social & Communication': [
      {'name': 'WhatsApp', 'icon': FontAwesomeIcons.whatsapp, 'color': const Color(0xFF25D366), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Facebook', 'icon': FontAwesomeIcons.facebookF, 'color': const Color(0xFF1877F2), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Instagram', 'icon': FontAwesomeIcons.instagram, 'color': const Color(0xFFE1306C), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'X (Twitter)', 'icon': FontAwesomeIcons.xTwitter, 'color': const Color(0xFF000000), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Snapchat', 'icon': FontAwesomeIcons.snapchat, 'color': const Color(0xFFFFFC00), 'textColor': const Color(0xFF000000)},
      {'name': 'TikTok', 'icon': FontAwesomeIcons.tiktok, 'color': const Color(0xFF000000), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'LinkedIn', 'icon': FontAwesomeIcons.linkedinIn, 'color': const Color(0xFF0A66C2), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'YouTube', 'icon': FontAwesomeIcons.youtube, 'color': const Color(0xFFFF0000), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Telegram', 'icon': FontAwesomeIcons.telegram, 'color': const Color(0xFF26A5E4), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Pinterest', 'icon': FontAwesomeIcons.pinterestP, 'color': const Color(0xFFE60023), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Reddit', 'icon': FontAwesomeIcons.redditAlien, 'color': const Color(0xFFFF4500), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Discord', 'icon': FontAwesomeIcons.discord, 'color': const Color(0xFF5865F2), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Skype', 'icon': FontAwesomeIcons.skype, 'color': const Color(0xFF00AFF0), 'textColor': const Color(0xFFFFFFFF)},
    ],
    'Payment & Finance': [
      {'name': 'Vodafone Cash', 'icon': FontAwesomeIcons.wallet, 'color': const Color(0xFFE60000), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Etisalat Cash', 'icon': FontAwesomeIcons.wallet, 'color': const Color(0xFF007A33), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Orange Cash', 'icon': FontAwesomeIcons.wallet, 'color': const Color(0xFFFF7900), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'InstaPay', 'icon': FontAwesomeIcons.moneyBillTransfer, 'color': const Color(0xFF6C0AFF), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'PayPal', 'icon': FontAwesomeIcons.paypal, 'color': const Color(0xFF00457C), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Apple Pay', 'icon': FontAwesomeIcons.applePay, 'color': const Color(0xFF000000), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Google Pay', 'icon': FontAwesomeIcons.googlePay, 'color': const Color(0xFFEA4335), 'textColor': const Color(0xFFFFFFFF)},
    ],
    'Design & Development': [
      {'name': 'GitHub', 'icon': FontAwesomeIcons.github, 'color': const Color(0xFF181717), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Dribbble', 'icon': FontAwesomeIcons.dribbble, 'color': const Color(0xFFEA4C89), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Behance', 'icon': FontAwesomeIcons.behance, 'color': const Color(0xFF1769FF), 'textColor': const Color(0xFFFFFFFF)},
    ],
    'Entertainment': [
      {'name': 'Twitch', 'icon': FontAwesomeIcons.twitch, 'color': const Color(0xFF9146FF), 'textColor': const Color(0xFFFFFFFF)},
      {'name': 'Spotify', 'icon': FontAwesomeIcons.spotify, 'color': const Color(0xFF1DB954), 'textColor': const Color(0xFFFFFFFF)},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('social_links')
          .where('user_id', isEqualTo: user.uid)
          .get();

      final links = snapshot.docs
          .map((doc) => SocialLink.fromMap(doc.data(), doc.id))
          .toList();

      links.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      setState(() {
        _activeLinks = links;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading links: $e');
    }
  }

  bool get _isAllActive =>
      _activeLinks.isNotEmpty && _activeLinks.every((l) => l.isActive);

  Future<void> _toggleAllActive(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _activeLinks = _activeLinks.map((link) {
        return SocialLink(
          id: link.id,
          userId: link.userId,
          platformName: link.platformName,
          username: link.username,
          iconClass: link.iconClass,
          bgColor: link.bgColor,
          textColor: link.textColor,
          isActive: value,
          sortOrder: link.sortOrder,
          iconUrl: link.iconUrl,
        );
      }).toList();
    });

    for (final link in _activeLinks) {
      await FirebaseFirestore.instance
          .collection('social_links')
          .doc(link.id)
          .update({'is_active': value});
    }
  }

  Future<void> _toggleLinkActive(SocialLink link, bool value) async {
    final index = _activeLinks.indexWhere((l) => l.id == link.id);
    if (index == -1) return;

    final updatedLink = SocialLink(
      id: link.id,
      userId: link.userId,
      platformName: link.platformName,
      username: link.username,
      iconClass: link.iconClass,
      bgColor: link.bgColor,
      textColor: link.textColor,
      isActive: value,
      sortOrder: link.sortOrder,
      iconUrl: link.iconUrl,
    );

    setState(() {
      _activeLinks[index] = updatedLink;
    });

    await FirebaseFirestore.instance
        .collection('social_links')
        .doc(link.id)
        .update({'is_active': value});
  }

  bool _isDuplicateTitle(String title, {String? excludeId}) {
    return _activeLinks.any(
          (l) =>
      l.platformName.toLowerCase() == title.toLowerCase() &&
          l.id != excludeId,
    );
  }

  Future<bool> _confirmDelete(SocialLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.trashCan,
                      color: Color(0xFFEF4444),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Link?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101112),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete "${link.platformName}"?\nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
    return confirmed ?? false;
  }

  Future<void> _deleteLink(SocialLink link) async {
    if (link.iconUrl != null && link.iconUrl!.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(link.iconUrl!).delete();
      } catch (_) {}
    }

    await FirebaseFirestore.instance
        .collection('social_links')
        .doc(link.id)
        .delete();

    setState(() {
      _activeLinks.removeWhere((l) => l.id == link.id);
    });
  }

  Future<String?> _uploadIcon(File imageFile, String userId) async {
    try {
      final fileName =
          'social_icons/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _saveToFirebase({
    required String title,
    required String username,
    required Color bgColor,
    required Color textColor,
    File? customIcon,
    SocialLink? existingLink,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hexBg =
        '#${bgColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    final hexText =
        '#${textColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    String? iconUrl = existingLink?.iconUrl;

    if (customIcon != null) {
      final uploadedUrl = await _uploadIcon(customIcon, user.uid);
      if (uploadedUrl != null) {
        iconUrl = uploadedUrl;
      }
    }

    if (existingLink != null) {
      final updateData = {
        'platform_name': title,
        'username': username,
        'bg_color': hexBg,
        'text_color': hexText,
        'icon_class': title,
      };
      if (iconUrl != null) {
        updateData['icon_url'] = iconUrl;
      }

      await FirebaseFirestore.instance
          .collection('social_links')
          .doc(existingLink.id)
          .update(updateData);

      setState(() {
        final index = _activeLinks.indexWhere((l) => l.id == existingLink.id);
        if (index != -1) {
          _activeLinks[index] = SocialLink(
            id: existingLink.id,
            userId: user.uid,
            platformName: title,
            username: username,
            iconClass: title,
            bgColor: hexBg,
            textColor: hexText,
            isActive: existingLink.isActive,
            sortOrder: existingLink.sortOrder,
            iconUrl: iconUrl,
          );
        }
      });
    } else {
      final newDoc = {
        'user_id': user.uid,
        'platform_name': title,
        'username': username,
        'icon_class': title,
        'bg_color': hexBg,
        'text_color': hexText,
        'is_active': true,
        'sort_order': _activeLinks.length,
        if (iconUrl != null) 'icon_url': iconUrl,
      };

      final docRef =
      await FirebaseFirestore.instance.collection('social_links').add(newDoc);

      setState(() {
        _activeLinks.add(SocialLink(
          id: docRef.id,
          userId: user.uid,
          platformName: title,
          username: username,
          iconClass: title,
          bgColor: hexBg,
          textColor: hexText,
          isActive: true,
          sortOrder: _activeLinks.length,
          iconUrl: iconUrl,
        ));
      });
    }
  }

  void _openBottomSheet({
    required String title,
    dynamic icon,
    Color? bgColor,
    Color? textColor,
    SocialLink? existingLink,
  }) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LinkBottomSheet(
          initialTitle: title,
          initialUsername: existingLink?.username,
          initialIcon: icon ?? FontAwesomeIcons.link,
          initialBgColor: bgColor ?? const Color(0xFF101112),
          initialTextColor: textColor ?? const Color(0xFFFFFFFF),
          initialIconUrl: existingLink?.iconUrl,
          isDuplicateTitle: (name) =>
              _isDuplicateTitle(name, excludeId: existingLink?.id),
        );
      },
    );

    if (result != null) {
      await _saveToFirebase(
        title: result['title'],
        username: result['username'],
        bgColor: result['bgColor'],
        textColor: result['textColor'],
        customIcon: result['customIcon'],
        existingLink: existingLink,
      );
    }
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

  dynamic _getIconData(String name) {
    name = name.toLowerCase();
    if (name.contains('phone')) return FontAwesomeIcons.phone;
    if (name.contains('email')) return FontAwesomeIcons.solidEnvelope;
    if (name.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (name.contains('facebook')) return FontAwesomeIcons.facebookF;
    if (name.contains('instagram')) return FontAwesomeIcons.instagram;
    if (name.contains('twitter') || name == 'x' || name.contains('x (')) {
      return FontAwesomeIcons.xTwitter;
    }
    if (name.contains('snapchat')) return FontAwesomeIcons.snapchat;
    if (name.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (name.contains('linkedin')) return FontAwesomeIcons.linkedinIn;
    if (name.contains('youtube')) return FontAwesomeIcons.youtube;
    if (name.contains('telegram')) return FontAwesomeIcons.telegram;
    if (name.contains('pinterest')) return FontAwesomeIcons.pinterestP;
    if (name.contains('reddit')) return FontAwesomeIcons.redditAlien;
    if (name.contains('discord')) return FontAwesomeIcons.discord;
    if (name.contains('skype')) return FontAwesomeIcons.skype;
    if (name.contains('github')) return FontAwesomeIcons.github;
    if (name.contains('dribbble')) return FontAwesomeIcons.dribbble;
    if (name.contains('behance')) return FontAwesomeIcons.behance;
    if (name.contains('twitch')) return FontAwesomeIcons.twitch;
    if (name.contains('spotify')) return FontAwesomeIcons.spotify;
    if (name.contains('website') ||
        name.contains('site') ||
        name.contains('web')) {
      return FontAwesomeIcons.globe;
    }
    if (name.contains('location') || name.contains('map')) {
      return FontAwesomeIcons.locationDot;
    }
    if (name.contains('vodafone') ||
        name.contains('etisalat') ||
        name.contains('orange') ||
        name.contains('wallet')) {
      return FontAwesomeIcons.wallet;
    }
    if (name.contains('instapay') || name.contains('money')) {
      return FontAwesomeIcons.moneyBillTransfer;
    }
    if (name.contains('paypal')) return FontAwesomeIcons.paypal;
    if (name.contains('apple')) return FontAwesomeIcons.applePay;
    if (name.contains('google')) return FontAwesomeIcons.googlePay;
    return FontAwesomeIcons.link;
  }

  Widget _buildLinkIcon(SocialLink link, Color bgColor, Color textColor) {
    if (link.iconUrl != null && link.iconUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: link.iconUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 40,
            height: 40,
            color: bgColor,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 40,
            height: 40,
            color: bgColor,
            child: Center(
              child: FaIcon(
                _getIconData(link.platformName),
                color: textColor,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: FaIcon(
          _getIconData(link.platformName),
          color: textColor,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCategory(String title, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101112),
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            final alreadyAdded = _isDuplicateTitle(item['name'].toString());

            return Column(
              children: [
                InkWell(
                  onTap: alreadyAdded
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${item['name']} is already added. Swipe right to edit.'),
                    ),
                  )
                      : () {
                    _openBottomSheet(
                      title: item['name'].toString(),
                      icon: item['icon'],
                      bgColor: item['color'] as Color,
                      textColor: item['textColor'] as Color,
                    );
                  },
                  child: Opacity(
                    opacity: alreadyAdded ? 0.4 : 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FaIcon(
                                item['icon'],
                                color: item['textColor'] as Color,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item['name'].toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF101112),
                              ),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Center(
                              child: Icon(
                                alreadyAdded ? Icons.check : Icons.add,
                                color: alreadyAdded
                                    ? const Color(0xFF34A853)
                                    : const Color(0xFF9A9EA6),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    color: Colors.grey.shade50,
                    height: 1,
                    thickness: 1,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF4F5F7);
    const Color textColorDark = Color(0xFF101112);
    const Color neonGreen = Color(0xFFB4E322);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                          Icons.arrow_back,
                          size: 16,
                          color: textColorDark,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Social Links',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textColorDark,
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Active Links Card
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 24),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Active all',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: textColorDark,
                                        ),
                                      ),
                                      CupertinoSwitch(
                                        value: _isAllActive,
                                        activeColor: neonGreen,
                                        onChanged: _activeLinks.isEmpty
                                            ? null
                                            : _toggleAllActive,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_activeLinks.isNotEmpty) ...[
                                  Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.grey.shade50),
                                  ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: _activeLinks.length,
                                    onReorder: (oldIndex, newIndex) async {
                                      setState(() {
                                        if (newIndex > oldIndex) {
                                          newIndex -= 1;
                                        }
                                        final item = _activeLinks
                                            .removeAt(oldIndex);
                                        _activeLinks.insert(
                                            newIndex, item);
                                      });

                                      for (int i = 0;
                                      i < _activeLinks.length;
                                      i++) {
                                        await FirebaseFirestore.instance
                                            .collection('social_links')
                                            .doc(_activeLinks[i].id)
                                            .update({'sort_order': i});
                                      }
                                    },
                                    itemBuilder: (context, index) {
                                      final link = _activeLinks[index];
                                      final bgColor =
                                      _getColorFromHex(link.bgColor);
                                      final textColor =
                                      _getColorFromHex(link.textColor);

                                      return Dismissible(
                                        key: ValueKey(link.id),
                                        direction:
                                        DismissDirection.horizontal,
                                        background: Container(
                                          color: const Color(0xFF299BF6),
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(
                                              left: 24),
                                          child: const FaIcon(
                                              FontAwesomeIcons.pen,
                                              color: Colors.white,
                                              size: 20),
                                        ),
                                        secondaryBackground: Container(
                                          color: const Color(0xFFF15341),
                                          alignment:
                                          Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                              right: 24),
                                          child: const FaIcon(
                                              FontAwesomeIcons.trashCan,
                                              color: Colors.white,
                                              size: 20),
                                        ),
                                        confirmDismiss:
                                            (direction) async {
                                          if (direction ==
                                              DismissDirection
                                                  .startToEnd) {
                                            _openBottomSheet(
                                              title: link.platformName,
                                              icon: _getIconData(
                                                  link.platformName),
                                              bgColor: bgColor,
                                              textColor: textColor,
                                              existingLink: link,
                                            );
                                            return false;
                                          }
                                          if (direction ==
                                              DismissDirection
                                                  .endToStart) {
                                            return _confirmDelete(link);
                                          }
                                          return false;
                                        },
                                        onDismissed: (direction) {
                                          if (direction ==
                                              DismissDirection
                                                  .endToStart) {
                                            _deleteLink(link);
                                          }
                                        },
                                        child: Material(
                                          color: Colors.white,
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 20,
                                                    vertical: 12),
                                                child: Row(
                                                  children: [
                                                    _buildLinkIcon(link,
                                                        bgColor, textColor),
                                                    const SizedBox(
                                                        width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          Text(
                                                            link.platformName,
                                                            style:
                                                            const TextStyle(
                                                              fontSize: 15,
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
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            link.username,
                                                            style:
                                                            const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w500,
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
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child:
                                                      CupertinoSwitch(
                                                        value:
                                                        link.isActive,
                                                        activeColor:
                                                        neonGreen,
                                                        onChanged:
                                                            (value) =>
                                                            _toggleLinkActive(
                                                                link,
                                                                value),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 8),
                                                    const Icon(
                                                      Icons
                                                          .drag_indicator,
                                                      color: Color(
                                                          0xFFC0C4CC),
                                                      size: 22,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (index !=
                                                  _activeLinks.length -
                                                      1)
                                                Divider(
                                                    height: 1,
                                                    thickness: 1,
                                                    color: Colors
                                                        .grey.shade50),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ] else
                                  const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'No links added yet',
                                      style: TextStyle(
                                          color: Color(0xFF9A9EA6)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              _openBottomSheet(title: 'Custom Link');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: textColorDark,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'Add new link',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Categories
                    ..._categories.entries.map((entry) {
                      return _buildCategory(entry.key, entry.value);
                    }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// Bottom Sheet - Add / Edit Link
/// ============================================================
class _LinkBottomSheet extends StatefulWidget {
  final String initialTitle;
  final String? initialUsername;
  final dynamic initialIcon;
  final Color initialBgColor;
  final Color initialTextColor;
  final String? initialIconUrl;
  final bool Function(String title) isDuplicateTitle;

  const _LinkBottomSheet({
    required this.initialTitle,
    this.initialUsername,
    required this.initialIcon,
    required this.initialBgColor,
    required this.initialTextColor,
    this.initialIconUrl,
    required this.isDuplicateTitle,
  });

  @override
  State<_LinkBottomSheet> createState() => _LinkBottomSheetState();
}

class _LinkBottomSheetState extends State<_LinkBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late Color _bgColor;
  late Color _textColor;
  File? _customIcon;
  String? _errorText;

  final ImagePicker _picker = ImagePicker();

  final List<Color> _colorOptions = [
    const Color(0xFF101112),
    const Color(0xFFFFFFFF),
    const Color(0xFFEA4335),
    const Color(0xFF34B7F1),
    const Color(0xFF25D366),
    const Color(0xFF1877F2),
    const Color(0xFFE1306C),
    const Color(0xFF0A66C2),
    const Color(0xFFFF0000),
    const Color(0xFF6C0AFF),
    const Color(0xFFB4E322),
    const Color(0xFFFF7900),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialTitle == 'Custom Link' ? '' : widget.initialTitle,
    );
    _usernameController = TextEditingController(
      text: _stripPrefixForEditing(
          widget.initialTitle, widget.initialUsername ?? ''),
    );
    _bgColor = widget.initialBgColor;
    _textColor = widget.initialTextColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _stripPrefixForEditing(String platformName, String storedValue) {
    if (storedValue.startsWith('tel:')) {
      return storedValue.replaceFirst('tel:', '');
    }
    if (storedValue.startsWith('https://wa.me/')) {
      return storedValue.replaceFirst('https://wa.me/', '');
    }
    if (storedValue.startsWith('mailto:')) {
      return storedValue.replaceFirst('mailto:', '');
    }
    return storedValue;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _customIcon = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _showColorPicker(bool isBg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isBg ? 'Select Background Color' : 'Select Text Color',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorOptions.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isBg) {
                      _bgColor = color;
                    } else {
                      _textColor = color;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String? _validate(String name, String rawInput) {
    final lowerName = name.toLowerCase();
    final value = rawInput.trim();

    if (value.isEmpty) return 'Please enter the required value';

    if (lowerName.contains('phone') || lowerName.contains('whatsapp')) {
      final digitsOnly = value.replaceAll(RegExp(r'[^0-9+]'), '');
      final digitCount = digitsOnly.replaceAll('+', '').length;
      if (digitCount < 7) return 'Invalid phone number';
      return null;
    }

    if (lowerName.contains('email')) {
      final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) return 'Invalid email format';
      return null;
    }

    if (lowerName.contains('website') ||
        lowerName.contains('site') ||
        lowerName.contains('web')) {
      final cleaned = value.startsWith('http') ? value : 'https://$value';
      if (!cleaned.contains('.')) return 'Invalid website URL';
      return null;
    }

    return null;
  }

  String _formatFinalValue(String name, String rawInput) {
    final lowerName = name.toLowerCase();
    final value = rawInput.trim();

    if (lowerName.contains('phone')) {
      return 'tel:${value.replaceAll(RegExp(r'[^0-9+]'), '')}';
    }
    if (lowerName.contains('whatsapp')) {
      return 'https://wa.me/${value.replaceAll(RegExp(r'[^0-9+]'), '')}';
    }
    if (lowerName.contains('email')) {
      return 'mailto:$value';
    }
    if ((lowerName.contains('website') ||
        lowerName.contains('site') ||
        lowerName.contains('web')) &&
        !value.startsWith('http')) {
      return 'https://$value';
    }
    return value;
  }

  void _handleSave() {
    final title = _nameController.text.trim();
    final rawUsername = _usernameController.text.trim();

    if (title.isEmpty || rawUsername.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields');
      return;
    }

    if (widget.isDuplicateTitle(title)) {
      setState(
              () => _errorText = 'A link with the name "$title" already exists');
      return;
    }

    final validationError = _validate(title, rawUsername);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() => _errorText = null);

    Navigator.pop(context, {
      'title': title,
      'username': _formatFinalValue(title, rawUsername),
      'bgColor': _bgColor,
      'textColor': _textColor,
      'customIcon': _customIcon,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Icon Preview
            GestureDetector(
              onTap: _pickImage,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _customIcon != null
                          ? Image.file(
                        _customIcon!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                          : (widget.initialIconUrl != null &&
                          widget.initialIconUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                        imageUrl: widget.initialIconUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: FaIcon(
                            widget.initialIcon is IconData
                                ? widget.initialIcon
                                : FontAwesomeIcons.link,
                            color: _textColor,
                            size: 32,
                          ),
                        ),
                      )
                          : Center(
                        child: FaIcon(
                          widget.initialIcon is IconData
                              ? widget.initialIcon
                              : FontAwesomeIcons.link,
                          color: _textColor,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TAP TO CHANGE ICON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A9EA6),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              widget.initialTitle == 'Custom Link'
                  ? 'Add Custom Link'
                  : 'Edit ${widget.initialTitle}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF101112),
              ),
            ),
            const SizedBox(height: 24),

            // Color Pickers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showColorPicker(true),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _bgColor,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bg Color',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF101112),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 32,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showColorPicker(false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Text Color',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF101112),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _textColor,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Platform Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLATFORM NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A9EA6),
                    ),
                  ),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) {
                      if (_errorText != null) setState(() => _errorText = null);
                    },
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101112),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Username
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'USERNAME / PROFILE URL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A9EA6),
                    ),
                  ),
                  TextField(
                    controller: _usernameController,
                    onChanged: (_) {
                      if (_errorText != null) setState(() => _errorText = null);
                    },
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101112),
                    ),
                    decoration: const InputDecoration(
                      hintText: '@username or link',
                      hintStyle: TextStyle(
                        color: Color(0xFF9A9EA6),
                        fontWeight: FontWeight.w500,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Save Button
            GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101112),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'Save Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}