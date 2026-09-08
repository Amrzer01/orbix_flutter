import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/profile.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _roleTypeController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentAvatarUrl;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final profile = Profile.fromMap(doc.data()!, doc.id);
        setState(() {
          _fullNameController.text = profile.fullName;
          _roleTypeController.text = profile.roleType;
          _bioController.text = profile.bio;
          _currentAvatarUrl = profile.avatarUrl;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      String? avatarUrl = _currentAvatarUrl;
      
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        avatarUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'full_name': _fullNameController.text.trim(),
        'role_type': _roleTypeController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar_url': avatarUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Color(0xFFC8F331)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF101112), fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF101112)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null 
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty 
                              ? NetworkImage(_currentAvatarUrl!) 
                              : null),
                      child: (_selectedImage == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8F331),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                      child: const Icon(Icons.edit, size: 14, color: Color(0xFF101112)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 45,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FULL NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9A9EA6), letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _fullNameController,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101112)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4F5F7),
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9A9EA6), size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                validator: (value) => value!.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 55,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('JOB TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9A9EA6), letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _roleTypeController,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101112)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4F5F7),
                                  prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF9A9EA6), size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  hintText: 'e.g. Developer',
                                  hintStyle: TextStyle(color: const Color(0xFF9A9EA6).withValues(alpha: 0.7)),
                                ),
                                validator: (value) => value!.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text('SHORT BIO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9A9EA6), letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101112)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Icon(Icons.align_horizontal_left, color: Color(0xFF9A9EA6), size: 18),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        hintText: 'Tell us about yourself...',
                        hintStyle: TextStyle(color: const Color(0xFF9A9EA6).withValues(alpha: 0.7)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF101112),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
