import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminEditUserPage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const AdminEditUserPage({
    super.key,
    required this.uid,
    required this.userData,
  });

  @override
  State<AdminEditUserPage> createState() => _AdminEditUserPageState();
}

class _AdminEditUserPageState extends State<AdminEditUserPage> {
  final nameCtrl = TextEditingController();
  final customCourseCtrl = TextEditingController();
  final skillCtrl = TextEditingController();

  String? selectedCourse;
  String selectedRole = 'user';

  bool loading = false;
  bool checkingRole = true;
  bool isSuperAdmin = false;
  bool targetIsSuperAdmin = false;

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);

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

  @override
  void initState() {
    super.initState();
    _loadTargetUserData();
    _checkCurrentAdminRole();
  }

  void _loadTargetUserData() {
    nameCtrl.text = widget.userData['name']?.toString() ?? '';

    final savedCourse = widget.userData['course']?.toString() ??
        widget.userData['education']?.toString() ??
        '';

    if (savedCourse.isNotEmpty) {
      if (courseOptions.contains(savedCourse)) {
        selectedCourse = savedCourse;
      } else {
        courseOptions.insert(courseOptions.length - 1, savedCourse);
        selectedCourse = savedCourse;
      }
    }

    final skills = widget.userData['skills'];

    if (skills is List) {
      skillCtrl.text = skills.map((e) => e.toString()).join(', ');
    } else {
      skillCtrl.text = skills?.toString() ?? '';
    }

    final role = widget.userData['role']?.toString().toLowerCase() ?? 'user';

    if (role == 'superadmin') {
      selectedRole = 'superadmin';
      targetIsSuperAdmin = true;
    } else if (role == 'admin') {
      selectedRole = 'admin';
      targetIsSuperAdmin = false;
    } else {
      selectedRole = 'user';
      targetIsSuperAdmin = false;
    }
  }

  Future<void> _checkCurrentAdminRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;

      setState(() {
        checkingRole = false;
        isSuperAdmin = false;
      });

      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final data = doc.data() ?? {};
      final currentRole = data['role']?.toString().toLowerCase() ?? 'user';

      if (!mounted) return;

      setState(() {
        isSuperAdmin = currentRole == 'superadmin';
        checkingRole = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        checkingRole = false;
        isSuperAdmin = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = nameCtrl.text.trim();
    final skillsText = skillCtrl.text.trim();

    final course = selectedCourse == 'Other'
        ? customCourseCtrl.text.trim()
        : selectedCourse?.trim();

    if (name.isEmpty) {
      showMessage('Name cannot be empty.');
      return;
    }

    if (course == null || course.isEmpty) {
      showMessage('Please select or enter a course.');
      return;
    }

    if (skillsText.isEmpty) {
      showMessage('Please enter at least one skill.');
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == widget.uid && selectedRole != 'superadmin') {
      showMessage('You cannot remove your own superadmin role.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final skills = skillsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final Map<String, dynamic> updateData = {
        'name': name,
        'course': course,
        'school': 'INTI College',
        'education': FieldValue.delete(),
        'skills': skills,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only superadmin can change role.
      // But superadmin accounts cannot be changed/demoted here.
      if (isSuperAdmin && !targetIsSuperAdmin) {
        updateData['role'] = selectedRole;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update(updateData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile updated successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    customCourseCtrl.dispose();
    skillCtrl.dispose();
    super.dispose();
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _courseDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCourse,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Course',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
            selectedCourse = value;

            if (value != 'Other') {
              customCourseCtrl.clear();
            }
          });
        },
      ),
    );
  }

  Widget _roleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedRole,
        decoration: InputDecoration(
          labelText: 'Role',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'user',
            child: Text('User'),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Text('Admin'),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            selectedRole = value;
          });
        },
      ),
    );
  }

  Widget _lockedSuperAdminRoleBox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        enabled: false,
        controller: TextEditingController(text: 'Super Admin'),
        decoration: InputDecoration(
          labelText: 'Role',
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData['email']?.toString() ?? 'No Email';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Edit User Profile'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: checkingRole
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: navy,
              child: Text(
                nameCtrl.text.isNotEmpty
                    ? nameCtrl.text[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              email,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            _input(
              label: 'Name',
              controller: nameCtrl,
            ),

            _courseDropdown(),

            if (selectedCourse == 'Other')
              _input(
                label: 'Enter Course',
                controller: customCourseCtrl,
              ),

            _input(
              label: 'Skills',
              controller: skillCtrl,
              maxLines: 2,
            ),

            if (isSuperAdmin && targetIsSuperAdmin)
              _lockedSuperAdminRoleBox()
            else if (isSuperAdmin)
              _roleDropdown(),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Save Changes',
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