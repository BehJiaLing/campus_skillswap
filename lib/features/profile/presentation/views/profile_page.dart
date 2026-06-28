import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';
import 'profile_edit_page.dart';
import 'settings_page.dart';
import 'user_profile_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Back to Login'),
          ),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF4F7FB),
      bottomNavigationBar: const BottomSidebar(currentIndex: 4),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load profile'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: green));
          }
          final data = snapshot.data?.data();
          if (data == null) {
            return Center(
              child: FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/create-profile'),
                child: const Text('Create Profile'),
              ),
            );
          }
          final name = (data['name'] ?? data['fullName'] ?? 'Student')
              .toString();
          final campus = (data['campus'] ?? data['school'] ?? '')
              .toString()
              .trim();
          final course = (data['course'] ?? 'Student').toString();
          final photo = (data['photoUrl'] ?? data['profileImageUrl'] ?? '')
              .toString();
          final skills = data['skills'] is Iterable
              ? (data['skills'] as Iterable)
                    .map((item) => item.toString())
                    .toList()
              : <String>[];
          final rating = (data['averageRating'] as num?)?.toDouble() ?? 0;
          final points = (data['rewardPoints'] as num?)?.toInt() ?? 0;
          final colors = Theme.of(context).colorScheme;
          return SafeArea(
            child: Column(
              children: [
                SkillSwapPageHeader(
                  title: 'My Profile',
                  subtitle: 'Your skills, reputation and campus activity.',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: .6),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFFE8EEFF),
                                  backgroundImage: photo.isEmpty
                                      ? null
                                      : NetworkImage(photo),
                                  child: photo.isEmpty
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 42,
                                          color: navy,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        course,
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        campus.isEmpty ? 'Campus: TBC' : campus,
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  tooltip: 'Edit profile',
                                  style: IconButton.styleFrom(
                                    foregroundColor: navy,
                                    backgroundColor: const Color(0xFFE8EEFF),
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileEditPage(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                              ],
                            ),
                            if (skills.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: skills
                                      .map(
                                        (skill) => Chip(
                                          label: Text(skill),
                                          side: BorderSide.none,
                                          backgroundColor: green.withValues(
                                            alpha: .10,
                                          ),
                                          labelStyle: const TextStyle(
                                            color: green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child:
                                StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: FirebaseFirestore.instance
                                      .collection('posts')
                                      .where('userId', isEqualTo: user.uid)
                                      .snapshots(),
                                  builder: (context, posts) => _stat(
                                    context,
                                    '${posts.data?.docs.where((doc) => doc.data()['isDeleted'] != true).length ?? 0}',
                                    'Posts',
                                    Icons.article_rounded,
                                    () => Navigator.pushNamed(
                                      context,
                                      '/my-posts',
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _stat(
                              context,
                              rating.toStringAsFixed(1),
                              'Rating',
                              Icons.star_rounded,
                              () => showUserReviewsDialog(
                                context,
                                userId: user.uid,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _stat(
                              context,
                              '$points',
                              'Points',
                              Icons.workspace_premium_rounded,
                              () =>
                                  _showPointsBarcode(context, points, user.uid),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Account shortcuts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _shortcut(
                        context,
                        Icons.handshake_rounded,
                        'Helper Posts',
                        'Requests where you are the confirmed helper',
                        () => Navigator.pushNamed(context, '/helper-posts'),
                      ),
                      const SizedBox(height: 9),
                      _shortcut(
                        context,
                        Icons.settings_rounded,
                        'Settings',
                        'Theme, account and sign-out options',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      _shortcut(
                        context,
                        Icons.logout_rounded,
                        'Logout',
                        'Sign out from this device',
                        () => _logout(context, user.uid),
                        destructive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: navy, size: 25),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcut(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
        ),
        leading: CircleAvatar(
          backgroundColor: (destructive ? Colors.red : green).withValues(
            alpha: .11,
          ),
          child: Icon(icon, color: destructive ? Colors.red : green),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: destructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logout(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Are you sure you want to sign out from Campus SkillSwap?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isOnline': false,
    });
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _showPointsBarcode(BuildContext context, int points, String userId) {
    final seed = userId.codeUnits.fold<int>(points + 1, (a, b) => a + b);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close reward redemption',
      barrierColor: Colors.black.withValues(alpha: .64),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.sizeOf(dialogContext).width * .9,
                constraints: const BoxConstraints(maxWidth: 460),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF102A72), Color(0xFF17469A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reward Redemption',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Campus SkillSwap rewards',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Text(
                            'Available points',
                            style: TextStyle(
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$points',
                            style: const TextStyle(
                              color: green,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 130,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE3E8F2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(42, (index) {
                                final width = ((seed + index * 7) % 3 + 1)
                                    .toDouble();
                                return Container(
                                  width: width,
                                  margin: EdgeInsets.only(
                                    right: index.isEven ? 2 : 1,
                                  ),
                                  color: index % 4 == 0
                                      ? Colors.transparent
                                      : Colors.black,
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Show this barcode when redeeming your SkillSwap points.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.4,
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: navy,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(animation),
          child: child,
        ),
      ),
    );
  }
}
