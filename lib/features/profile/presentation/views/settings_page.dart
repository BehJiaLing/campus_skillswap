import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);

  Future<void> _changePassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            SkillSwapPageHeader(
              title: 'Settings',
              subtitle: 'Personalize security and appearance.',
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: colors.outlineVariant.withValues(alpha: .6),
                        ),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8EEFF),
                        child: Icon(Icons.lock_reset_rounded, color: navy),
                      ),
                      title: const Text(
                        'Change Password',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Receive a secure reset link by email',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _changePassword(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppTheme.themeMode,
                    builder: (context, mode, _) => Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: SwitchListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: .6),
                          ),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: green.withValues(alpha: .12),
                          child: const Icon(
                            Icons.dark_mode_rounded,
                            color: green,
                          ),
                        ),
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Use a darker theme throughout the app',
                        ),
                        value: mode == ThemeMode.dark,
                        activeThumbColor: green,
                        onChanged: AppTheme.toggleTheme,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
