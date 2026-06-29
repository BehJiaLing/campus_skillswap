import 'package:flutter/material.dart';

import '../../../../core/widgets/skill_swap_page_header.dart';

class DeletedPostNoticePage extends StatelessWidget {
  const DeletedPostNoticePage({
    super.key,
    required this.postTitle,
    required this.message,
  });

  static const navy = Color(0xFF102A72);

  final String postTitle;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            SkillSwapPageHeader(
              title: 'Request Details',
              subtitle: postTitle,
              trailing: IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: .6),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.red.withValues(alpha: .1),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 34,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This post has been deleted',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.45,
                            color: colors.onSurfaceVariant,
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
