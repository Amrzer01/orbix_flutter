import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Tap to Exchange',
      subtitle: 'Share your profile, contacts, and custom links instantly with a single tap of your Orbix NFC card.',
      badgeText: 'INSTANT NFC',
      type: OnboardingType.nfcTap,
    ),
    OnboardingItem(
      title: 'One Link, All Socials',
      subtitle: 'Bring all your digital identities, social links, and business details together in one sleek, customizable profile.',
      badgeText: 'SMART PROFILE',
      type: OnboardingType.socialHub,
    ),
    OnboardingItem(
      title: 'Connect & Network Effortlessly',
      subtitle: 'Network with people nearby, exchange messages in real-time, and manage your digital identity seamlessly.',
      badgeText: 'REAL-TIME NETWORK',
      type: OnboardingType.networking,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101112),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC8F331).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.nfcSymbol,
                            size: 16,
                            color: Color(0xFFC8F331),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ORBIX',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xFF101112),
                        ),
                      ),
                    ],
                  ),
                  // Skip Button
                  if (_currentIndex < _items.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6C757D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Main PageView Illustration & Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration Container
                            Container(
                              height: 280,
                              width: double.infinity,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 2D Line Art Vector Illustration
                                  _buildIllustrationWidget(item.type),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8F331).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFC8F331),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.badgeText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101112),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF101112),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6C757D),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Section (Page Indicator + Action Button)
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, bottom: 16, top: 12),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? const Color(0xFF101112)
                              : const Color(0xFFDEE2E6),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentIndex == index
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFC8F331).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF101112),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == _items.length - 1 ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC8F331),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationWidget(OnboardingType type) {
    switch (type) {
      case OnboardingType.nfcTap:
        return const NfcTapIllustration();
      case OnboardingType.socialHub:
        return const SocialHubIllustration();
      case OnboardingType.networking:
        return const NetworkingIllustration();
    }
  }
}

enum OnboardingType { nfcTap, socialHub, networking }

class OnboardingItem {
  final String title;
  final String subtitle;
  final String badgeText;
  final OnboardingType type;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.type,
  });
}

// -----------------------------------------------------------------------------
// 2D Line Art Illustration 1: NFC Tap Vector Art
// -----------------------------------------------------------------------------
class NfcTapIllustration extends StatelessWidget {
  const NfcTapIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Concentric Pulsing Wave Rings
        CustomPaint(
          size: const Size(220, 220),
          painter: WaveRingsPainter(),
        ),
        // Phone Outline
        Positioned(
          left: 45,
          child: Container(
            width: 110,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF101112), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101112),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F331).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF101112), width: 2),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.nfcSymbol,
                      size: 24,
                      color: Color(0xFF101112),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101112),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PAIRING...',
                    style: TextStyle(
                      color: Color(0xFFC8F331),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Smart NFC Card Outline
        Positioned(
          right: 35,
          top: 55,
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 145,
              height: 95,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF101112),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8F331), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC8F331).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ORBIX',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8F331),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Smart NFC Card',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const FaIcon(
                        FontAwesomeIcons.wifi,
                        color: Color(0xFFC8F331),
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2D Line Art Illustration 2: Social Links Hub Vector Art
// -----------------------------------------------------------------------------
class SocialHubIllustration extends StatelessWidget {
  const SocialHubIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Connecting Vector Network Lines
        CustomPaint(
          size: const Size(240, 200),
          painter: SocialNetworkPainter(),
        ),
        // Central Orbix Hub Node
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF101112),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC8F331), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC8F331).withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.solidUser,
              size: 26,
              color: Color(0xFFC8F331),
            ),
          ),
        ),
        // Satellite Social Node 1: WhatsApp (Top Right)
        Positioned(
          top: 35,
          right: 40,
          child: _buildSocialNode(FontAwesomeIcons.whatsapp, const Color(0xFF25D366)),
        ),
        // Satellite Social Node 2: Instagram (Top Left)
        Positioned(
          top: 40,
          left: 45,
          child: _buildSocialNode(FontAwesomeIcons.instagram, const Color(0xFFE1306C)),
        ),
        // Satellite Social Node 3: LinkedIn (Bottom Right)
        Positioned(
          bottom: 35,
          right: 50,
          child: _buildSocialNode(FontAwesomeIcons.linkedinIn, const Color(0xFF0A66C2)),
        ),
        // Satellite Social Node 4: Phone (Bottom Left)
        Positioned(
          bottom: 35,
          left: 45,
          child: _buildSocialNode(FontAwesomeIcons.phone, const Color(0xFF34B7F1)),
        ),
        // Satellite Social Node 5: X (Mid Left)
        Positioned(
          top: 85,
          left: 10,
          child: _buildSocialNode(FontAwesomeIcons.xTwitter, const Color(0xFF000000)),
        ),
        // Satellite Social Node 6: YouTube (Mid Right)
        Positioned(
          top: 90,
          right: 15,
          child: _buildSocialNode(FontAwesomeIcons.youtube, const Color(0xFFFF0000)),
        ),
      ],
    );
  }

  Widget _buildSocialNode(dynamic icon, Color brandColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF101112), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: FaIcon(
          icon,
          size: 20,
          color: brandColor,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2D Line Art Illustration 3: Real-Time Connections & Wallet Vector Art
// -----------------------------------------------------------------------------
class NetworkingIllustration extends StatelessWidget {
  const NetworkingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Radar Rings
        CustomPaint(
          size: const Size(220, 220),
          painter: WaveRingsPainter(),
        ),
        // Central Card User
        Container(
          width: 170,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF101112), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8F331),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF101112), width: 1.5),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.userCheck,
                        size: 18,
                        color: Color(0xFF101112),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Connection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF101112),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Exchanged 5 links',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6C757D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8F331),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Notification Badge (Top Right)
        Positioned(
          top: 30,
          right: 35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF101112),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8F331), width: 1.5),
            ),
            child: const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.solidCommentDots,
                  color: Color(0xFFC8F331),
                  size: 11,
                ),
                SizedBox(width: 6),
                Text(
                  'Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painters for 2D Vector Backgrounds
// -----------------------------------------------------------------------------
// Removed VectorGridPainter

class WaveRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint1 = Paint()
      ..color = const Color(0xFF101112).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paint2 = Paint()
      ..color = const Color(0xFFC8F331).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 40, paint1);
    canvas.drawCircle(center, 70, paint2);
    canvas.drawCircle(center, 100, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SocialNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final topR = Offset(size.width * 0.78, size.height * 0.25);
    final topL = Offset(size.width * 0.22, size.height * 0.27);
    final botR = Offset(size.width * 0.75, size.height * 0.78);
    final botL = Offset(size.width * 0.22, size.height * 0.78);
    final midR = Offset(size.width * 0.85, size.height * 0.56);
    final midL = Offset(size.width * 0.13, size.height * 0.53);

    final linePaint = Paint()
      ..color = const Color(0xFF101112)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final neonDashPaint = Paint()
      ..color = const Color(0xFFC8F331)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, topR, linePaint);
    canvas.drawLine(center, topL, neonDashPaint);
    canvas.drawLine(center, botR, linePaint);
    canvas.drawLine(center, botL, neonDashPaint);
    canvas.drawLine(center, midR, neonDashPaint);
    canvas.drawLine(center, midL, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
