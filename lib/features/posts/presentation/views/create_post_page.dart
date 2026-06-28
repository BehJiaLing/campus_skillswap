import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';
import '../view_models/create_post_view_model.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key, required this.viewModel});
  final CreatePostViewModel viewModel;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final skillCtrl = TextEditingController();

  Future<void> _createPost() async {
    if (!widget.viewModel.isSignedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final created = await widget.viewModel.submit(
      title: titleCtrl.text,
      description: descriptionCtrl.text,
      skillNeeded: skillCtrl.text,
    );
    if (!mounted) return;
    if (created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request published successfully.')),
      );
      Navigator.pushReplacementNamed(context, '/post');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.errorMessage ?? 'Unable to create request.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    skillCtrl.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF4F7FB),
        bottomNavigationBar: const BottomSidebar(currentIndex: 2),
        body: SafeArea(
          child: Column(
            children: [
              const SkillSwapPageHeader(
                title: 'Create Request',
                subtitle:
                    'Describe the skill support you need from campus peers.',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: .6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: navy,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Request details',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Clear details help the right student understand your request.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _field(
                          titleCtrl,
                          'Post title',
                          'Example: Need help with Python assignment',
                          Icons.title_rounded,
                        ),
                        const SizedBox(height: 15),
                        _field(
                          skillCtrl,
                          'Skill needed',
                          'Example: Python',
                          Icons.psychology_alt_rounded,
                        ),
                        const SizedBox(height: 15),
                        _field(
                          descriptionCtrl,
                          'Description',
                          'Explain the task, expected help, and preferred timing.',
                          Icons.notes_rounded,
                          maxLines: 6,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: widget.viewModel.isSubmitting
                                ? null
                                : _createPost,
                            style: FilledButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: widget.viewModel.isSubmitting
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.publish_rounded),
                            label: Text(
                              widget.viewModel.isSubmitting
                                  ? 'Publishing...'
                                  : 'Publish Request',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1 ? Icon(icon, color: navy) : null,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF273449)
            : const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
      ),
    );
  }
}
