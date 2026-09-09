import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

import '../screens/home_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/social_edit_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/account_settings_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context,
                  icon: FontAwesomeIcons.house,
                  isActive: currentIndex == 0,
                  onTap: () {
                    if (currentIndex != 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                ),
                _buildNavItem(
                  context,
                  icon: FontAwesomeIcons.comment,
                  isActive: currentIndex == 1,
                  onTap: () {
                    if (currentIndex != 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const InboxScreen()),
                      );
                    }
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SocialEditScreen()),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1B1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.plus,
                        color: Color(0xFFC8F331),
                        size: 16,
                      ),
                    ),
                  ),
                ),
                _buildNavItem(
                  context,
                  icon: FontAwesomeIcons.bell,
                  isActive: currentIndex == 3,
                  onTap: () {
                    if (currentIndex != 3) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RequestsScreen()),
                      );
                    }
                  },
                ),
                _buildNavItem(
                  context,
                  icon: FontAwesomeIcons.gear,
                  isActive: currentIndex == 4,
                  onTap: () {
                    if (currentIndex != 4) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required dynamic icon,
        required bool isActive,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: FaIcon(
            icon,
            size: 18,
            color: isActive ? const Color(0xFFC8F331) : const Color(0xFF9A9EA6),
          ),
        ),
      ),
    );
  }
}