import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final eduCtrl = TextEditingController();
  final schoolCtrl = TextEditingController();
  final skillCtrl = TextEditingController();

  String role = 'user';
  bool loading = false;

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);

  @override
  void initState() {
    super.initState();

    nameCtrl.text = widget.userData['name']?.toString() ?? '';
    eduCtrl.text = widget.userData['education']?.toString() ?? '';
    schoolCtrl.text = widget.userData['school']?.toString() ?? '';

    final skills = widget.userData['skills'];

    if (skills is List) {
      skillCtrl.text = skills.map((e) => e.toString()).join(', ');
    } else {
      skillCtrl.text = skills?.toString() ?? '';
    }

    final savedRole =
    (widget.userData['role'] ?? 'user').toString().toLowerCase();

    if (savedRole == 'admin') {
      role = 'admin';
    } else {
      role = 'user';
    }
  }

  Future<void> _saveProfile() async {
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'name': nameCtrl.text.trim(),
        'education': eduCtrl.text.trim(),
        'school': schoolCtrl.text.trim(),
        'skills': skillCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'role': role,
      });

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
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    eduCtrl.dispose();
    schoolCtrl.dispose();
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
      body: SingleChildScrollView(
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

            _input(
              label: 'Education',
              controller: eduCtrl,
            ),

            _input(
              label: 'School / University',
              controller: schoolCtrl,
            ),

            _input(
              label: 'Skills',
              controller: skillCtrl,
              maxLines: 2,
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                initialValue: role,
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
                  if (value != null) {
                    setState(() {
                      role = value;
                    });
                  }
                },
              ),
            ),

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