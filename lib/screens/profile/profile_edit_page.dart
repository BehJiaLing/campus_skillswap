import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _courseController = TextEditingController();
  final _skillsController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _schoolController.text = data['school'] ?? '';
      _courseController.text = data['course'] ?? '';

      _skillsController.text =
          ((data['skills'] ?? []) as List).join(', ');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveProfile() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    List<String> skills =
    _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'name': _nameController.text,
      'school': _schoolController.text,
      'course': _courseController.text,
      'skills': skills,
      'updatedAt': Timestamp.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile Updated'),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xFFF1F1E8),

                borderRadius:
                BorderRadius.circular(25),

                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),

              child: Form(
                key: _formKey,

                child: Column(
          children: [

            GestureDetector(
              onTap: () {},

              child: const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFF6D718B),

                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 45,
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Edit Your Profile",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Name",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _nameController,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }

                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }

                return null;
              },

              decoration: InputDecoration(

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "School",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _schoolController,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'School cannot be empty';
                }

                return null;
              },

              decoration: InputDecoration(

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Course",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _courseController,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Course cannot be empty';
                }

                return null;
              },

              decoration: InputDecoration(

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Skills (Separate by comma)",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _skillsController,

              maxLines: 3,

              validator: (value) {

                if (value == null ||
                    value.trim().isEmpty) {

                  return 'Please enter at least one skill';
                }

                return null;
              },

              decoration: InputDecoration(

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: saveProfile,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF6D718B),

                  foregroundColor:
                  Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),

                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
        ),
    );
  }
}