import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'social_links_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String initialName;

  const ProfileSetupScreen({super.key, required this.initialName});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameController;
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingData = true;
  File? _selectedImage;
  String? _existingAvatarUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // التأكد إن اليوزر موجود والـ ID بتاعه مش فاضي عشان نمنع الشاشة الحمرا
      if (user != null && user.uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              if (data['full_name'] != null && data['full_name'].toString().isNotEmpty) {
                _nameController.text = data['full_name'];
              }
              if (data['role_type'] != null && data['role_type'] != 'User') {
                _roleController.text = data['role_type'];
              }
              if (data['bio'] != null) {
                _bioController.text = data['bio'];
              }
              if (data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty) {
                _existingAvatarUrl = data['avatar_url'];
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      // حماية إضافية قبل الحفظ
      if (user != null && user.uid.isNotEmpty) {
        String? downloadUrl = _existingAvatarUrl;

        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          await storageRef.putFile(_selectedImage!);
          downloadUrl = await storageRef.getDownloadURL();
        }

        Map<String, dynamic> updateData = {
          'full_name': _nameController.text.trim(),
          'role_type': _roleController.text.trim().isEmpty ? 'User' : _roleController.text.trim(),
          'bio': _bioController.text.trim(),
        };

        if (downloadUrl != null) {
          updateData['avatar_url'] = downloadUrl;
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SocialLinksSetupScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error. Please restart the app.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9A9EA6),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF4F5F7);
    const Color textColorDark = Color(0xFF101112);
    const Color textMuted = Color(0xFF9A9EA6);
    const Color neonGreen = Color(0xFFB4E322);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isFetchingData
            ? const Center(child: CircularProgressIndicator(color: textColorDark))
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: textColorDark,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: neonGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Profile Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColorDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            )
                                : (_existingAvatarUrl != null)
                                ? ClipOval(
                              child: Image.network(
                                _existingAvatarUrl!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            )
                                : const Center(
                              child: Icon(Icons.camera_alt, color: Color(0xFFC0C4CC), size: 32),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: textColorDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: neonGreen, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Who are you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColorDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Setup your personal info to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('FULL NAME'),
                          Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: textColorDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: textMuted, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildInputLabel('JOB TITLE / ROLE'),
                          Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _roleController,
                              style: const TextStyle(
                                color: textColorDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'User',
                                hintStyle: TextStyle(
                                  color: textColorDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(Icons.business_center_outlined, color: textMuted, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildInputLabel('SHORT BIO'),
                          Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _bioController,
                              maxLines: 4,
                              style: const TextStyle(
                                color: textColorDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Tell the world about your expertise...',
                                hintStyle: TextStyle(
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 56),
                                  child: Icon(Icons.subject_rounded, color: textMuted, size: 20),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _isLoading ? null : _saveProfile,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: textColorDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else ...[
                        const Text(
                          'Save & Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ]
                    ],
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