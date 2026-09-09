import 'package:flutter/material.dart';

import 'profile_setup_screen.dart';
import 'social_links_setup_screen.dart';
import 'credit_screen.dart';
import 'security_settings_screen.dart';
import 'design_card_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF101112),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF101112)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              children: [
                _buildSettingsCard(
                  context,
                  title: 'Profile Details',
                  subtitle: 'Update your name, bio, and avatar',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupScreen(initialName: ''),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  context,
                  title: 'Social Links',
                  subtitle: 'Manage your active social media platforms',
                  icon: Icons.link,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SocialLinksSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  context,
                  title: 'NFC Card Setup',
                  subtitle: 'Program and update your NFC card link',
                  icon: Icons.nfc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreditScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  context,
                  title: 'Create Design Card',
                  subtitle: 'Customize the look of your digital card',
                  icon: Icons.design_services_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DesignCardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  context,
                  title: 'Account & Security',
                  subtitle: 'Privacy, password, and logout options',
                  icon: Icons.security,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecuritySettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const BottomNavBar(currentIndex: 4),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFF101112),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101112),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A9EA6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFC0C4CC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}