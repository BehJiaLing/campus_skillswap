import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _nameCtrl = TextEditingController();
  final _customCourseCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  String? _selectedCourse;
  bool _loading = false;

  final Color navy = const Color(0xFF1A1F5E);
  final Color green = const Color(0xFF4CAF50);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);

  final List<String> courseOptions = [
    'Bachelor of Computer Science',
    'Bachelor of Information Technology',
    'Bachelor of Software Engineering',
    'Bachelor of Business Administration',
    'Bachelor of Accounting and Finance',
    'Bachelor of Mass Communication',
    'Bachelor of Psychology',
    'Bachelor of Biotechnology',

    'Diploma in Computer Science',
    'Diploma in Information Technology',
    'Diploma in Business',
    'Diploma in Accounting',
    'Diploma in Mass Communication',
    'Diploma in Hotel Management',
    'Diploma in Culinary Arts',
    'Diploma in Interior Design',
    'Diploma in Digital Media',
    'Diploma in Mechanical Engineering',
    'Diploma in Civil Engineering',

    'Foundation in Science',
    'Foundation in Business',
    'Foundation in Arts',
    'A-Level',

    'Other',
  ];

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final skillsText = _skillCtrl.text.trim();

    final course = _selectedCourse == 'Other'
        ? _customCourseCtrl.text.trim()
        : _selectedCourse?.trim();

    if (name.isEmpty || course == null || course.isEmpty || skillsText.isEmpty) {
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
      final skillsList = skillsText
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'course': course,
        'school': 'INTI College',
        'skills': skillsList,
        'photoUrl': '',
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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

  Widget _courseDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCourse,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select your course',
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
      items: courseOptions.map((course) {
        return DropdownMenuItem<String>(
          value: course,
          child: Text(
            course,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCourse = value;

          if (value != 'Other') {
            _customCourseCtrl.clear();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customCourseCtrl.dispose();
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
              child: CircleAvatar(
                radius: 45,
                backgroundColor: purple,
                child: Icon(
                  Icons.person,
                  size: 45,
                  color: purpleDeep,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Profile picture can be added later',
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
            _courseDropdown(),

            if (_selectedCourse == 'Other') ...[
              const SizedBox(height: 10),
              _inputField(
                controller: _customCourseCtrl,
                hintText: 'Enter your course',
              ),
            ],

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
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