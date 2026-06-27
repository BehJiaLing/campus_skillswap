import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _customCourseController = TextEditingController();
  final _skillsController = TextEditingController();

  String? _selectedCampus;
  String? _selectedCourse;

  bool isLoading = true;
  bool isSaving = false;

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
    loadUserData();
  }

  List<String> readSkills(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null) {
        final name =
            data['name']?.toString() ?? data['fullName']?.toString() ?? '';

        final campus =
            data['campus']?.toString() ?? data['school']?.toString() ?? '';

        final course = data['course']?.toString() ?? '';
        final skills = readSkills(data['skills']);

        _nameController.text = name;
        _skillsController.text = skills.join(', ');

        if (campusOptions.contains(campus)) {
          _selectedCampus = campus;
        }

        if (courseOptions.contains(course)) {
          _selectedCourse = course;
        } else if (course.isNotEmpty) {
          _selectedCourse = 'Other';
          _customCourseController.text = course;
        }
      }
    } catch (e) {
      showMessage('Error loading profile: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('User not logged in.');
      return;
    }

    final campus = _selectedCampus?.trim();

    final course = _selectedCourse == 'Other'
        ? _customCourseController.text.trim()
        : _selectedCourse?.trim();

    if (campus == null || campus.isEmpty) {
      showMessage('Please select your campus / branch.');
      return;
    }

    if (course == null || course.isEmpty) {
      showMessage('Please select or enter your course.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final skills = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'fullName': _nameController.text.trim(),
            'campus': campus,
            'school': campus,
            'course': course,
            'skills': skills,
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile Updated')));

      Navigator.pop(context);
    } catch (e) {
      showMessage('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF273449)
          : const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF12A875), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget campusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCampus,
      isExpanded: true,
      decoration: inputDecoration(hintText: 'Select your campus / branch'),
      items: campusOptions.map((campus) {
        return DropdownMenuItem<String>(
          value: campus,
          child: Text(campus, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please select your campus / branch';
        }

        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedCampus = value;
        });
      },
    );
  }

  Widget courseDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCourse,
      isExpanded: true,
      decoration: inputDecoration(hintText: 'Select your course'),
      items: courseOptions.map((course) {
        return DropdownMenuItem<String>(
          value: course,
          child: Text(course, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please select your course';
        }

        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedCourse = value;

          if (value != 'Other') {
            _customCourseController.clear();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customCourseController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            SkillSwapPageHeader(
              title: 'Edit Profile',
              subtitle: 'Keep your campus identity and skills up to date.',
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: .6),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge_rounded, color: Color(0xFF102A72)),
                            SizedBox(width: 8),
                            Text(
                              'Profile details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        label("Name"),
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
                          decoration: inputDecoration(
                            hintText: 'Your full name',
                          ),
                        ),

                        const SizedBox(height: 25),

                        label("Campus / Branch"),
                        const SizedBox(height: 8),

                        campusDropdown(),

                        const SizedBox(height: 25),

                        label("Course"),
                        const SizedBox(height: 8),

                        courseDropdown(),

                        if (_selectedCourse == 'Other') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customCourseController,
                            validator: (value) {
                              if (_selectedCourse == 'Other' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter your course';
                              }

                              return null;
                            },
                            decoration: inputDecoration(
                              hintText: 'Enter your course',
                            ),
                          ),
                        ],

                        const SizedBox(height: 25),

                        label("Skills (Separate by comma)"),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _skillsController,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter at least one skill';
                            }

                            return null;
                          },
                          decoration: inputDecoration(
                            hintText: 'e.g. Python, Canva, Excel',
                          ),
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : saveProfile,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF102A72),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}
