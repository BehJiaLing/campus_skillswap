import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _nameCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  bool _loading = false;

  XFile? _pickedImage;
  Uint8List? _imageBytes;

  final Color navy = const Color(0xFF1A1F5E);
  final Color green = const Color(0xFF4CAF50);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      _pickedImage = image;
      _imageBytes = bytes;
    });
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final course = _courseCtrl.text.trim();
    final school = _schoolCtrl.text.trim();
    final skillsText = _skillCtrl.text.trim();

    if (name.isEmpty || course.isEmpty || school.isEmpty || skillsText.isEmpty) {
      showMessage('Please fill in all fields.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('User not logged in.');
      return;
    }

    setState(() => _loading = true);

    try {
      String profileImageUrl = '';

      if (_pickedImage != null && _imageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');

        await ref.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        profileImageUrl = await ref.getDownloadURL();
      }

      final skillsList = skillsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'course': course,
        'school': school,
        'skills': skillsList,
        'photoUrl': profileImageUrl,
        'role': 'user',
        'profileCompleted': true,
        'suspended': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/post');
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: navy,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: navy, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    _schoolCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Create Profile'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: purple,
                      backgroundImage:
                      _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                      child: _imageBytes == null
                          ? Icon(
                        Icons.person,
                        size: 45,
                        color: purpleDeep,
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Tap image to upload profile picture',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            _label('Full Name'),
            const SizedBox(height: 6),
            _inputField(
              controller: _nameCtrl,
              hintText: 'Your full name',
            ),

            const SizedBox(height: 14),

            _label('Course'),
            const SizedBox(height: 6),
            _inputField(
              controller: _courseCtrl,
              hintText: 'e.g. Computer Science Diploma',
            ),

            const SizedBox(height: 14),

            _label('School'),
            const SizedBox(height: 6),
            _inputField(
              controller: _schoolCtrl,
              hintText: 'e.g. INTI College',
            ),

            const SizedBox(height: 14),

            _label('Skills'),
            const SizedBox(height: 6),
            _inputField(
              controller: _skillCtrl,
              hintText: 'e.g. Python, Canva, Excel',
              maxLines: 2,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}