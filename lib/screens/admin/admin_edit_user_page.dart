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

  String? selectedCampus;
  String? selectedCourse;
  String selectedRole = 'user';

  bool loading = false;
  bool checkingRole = true;
  bool isSuperAdmin = false;
  bool targetIsSuperAdmin = false;

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);

  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkBorder = const Color(0xFF374151);
  final Color darkField = const Color(0xFF111827);
  final Color darkPurple = const Color(0xFF312E81);

  final List<String> campusOptions = [
    'INTI International University',
    'INTI International College Subang',
    'INTI International College Penang',
    'INTI College Sabah',
  ];

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
    nameCtrl.text = widget.userData['name']?.toString() ??
        widget.userData['fullName']?.toString() ??
        '';

    final savedCampus = widget.userData['campus']?.toString() ??
        widget.userData['school']?.toString() ??
        '';

    if (savedCampus.isNotEmpty && campusOptions.contains(savedCampus)) {
      selectedCampus = savedCampus;
    }

    final savedCourse = widget.userData['course']?.toString() ??
        widget.userData['studentCourse']?.toString() ??
        widget.userData['programme']?.toString() ??
        widget.userData['program']?.toString() ??
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

    final role =
        widget.userData['role']?.toString().trim().toLowerCase() ?? 'user';

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
      final currentRole =
          data['role']?.toString().trim().toLowerCase() ?? 'user';

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
    final campus = selectedCampus?.trim();

    final course = selectedCourse == 'Other'
        ? customCourseCtrl.text.trim()
        : selectedCourse?.trim();

    if (name.isEmpty) {
      showMessage('Name cannot be empty.');
      return;
    }

    if (campus == null || campus.isEmpty) {
      showMessage('Please select a campus / branch.');
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
        'fullName': name,
        'campus': campus,
        'school': campus,
        'course': course,
        'education': FieldValue.delete(),
        'skills': skills,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

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
          backgroundColor: Colors.red,
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
      SnackBar(
        content: Text(message),
      ),
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
    required bool isDark,
    int maxLines = 1,
  }) {
    final fillColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF818CF8) : navy,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campusDropdown({required bool isDark}) {
    final fillColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCampus,
        isExpanded: true,
        dropdownColor: fillColor,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Campus / Branch',
          labelStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF818CF8) : navy,
              width: 1.4,
            ),
          ),
        ),
        items: campusOptions.map((campus) {
          return DropdownMenuItem<String>(
            value: campus,
            child: Text(
              campus,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedCampus = value;
          });
        },
      ),
    );
  }

  Widget _courseDropdown({required bool isDark}) {
    final fillColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCourse,
        isExpanded: true,
        dropdownColor: fillColor,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Course',
          labelStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF818CF8) : navy,
              width: 1.4,
            ),
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

  Widget _roleDropdown({required bool isDark}) {
    final fillColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedRole,
        dropdownColor: fillColor,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Role',
          labelStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF818CF8) : navy,
              width: 1.4,
            ),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'user', child: Text('User')),
          DropdownMenuItem(value: 'admin', child: Text('Admin')),
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

  Widget _lockedSuperAdminRoleBox({required bool isDark}) {
    final fillColor = isDark ? darkField : Colors.grey.shade200;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: 'Super Admin',
        enabled: false,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: 'Role',
          labelStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          suffixIcon: Icon(
            Icons.lock_outline,
            color: hintColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lineColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData['email']?.toString() ?? 'No Email';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? darkBg : bg;
    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;
    final avatarBg = isDark ? darkPurple : navy;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Edit User Profile'),
        backgroundColor: isDark ? darkBg : navy,
        foregroundColor: Colors.white,
      ),
      body: checkingRole
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lineColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.18 : 0.04,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: avatarBg,
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
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 24),

              _input(
                label: 'Name',
                controller: nameCtrl,
                isDark: isDark,
              ),

              _campusDropdown(isDark: isDark),

              _courseDropdown(isDark: isDark),

              if (selectedCourse == 'Other')
                _input(
                  label: 'Enter Course',
                  controller: customCourseCtrl,
                  isDark: isDark,
                ),

              _input(
                label: 'Skills',
                controller: skillCtrl,
                isDark: isDark,
                maxLines: 2,
              ),

              if (isSuperAdmin && targetIsSuperAdmin)
                _lockedSuperAdminRoleBox(isDark: isDark)
              else if (isSuperAdmin)
                _roleDropdown(isDark: isDark),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    isDark ? const Color(0xFF312E81) : navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    isDark ? darkBorder : Colors.grey.shade300,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Changes will update the selected user profile only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}