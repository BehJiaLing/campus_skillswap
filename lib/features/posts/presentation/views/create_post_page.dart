import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../view_models/create_post_view_model.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key, required this.viewModel});

  final CreatePostViewModel viewModel;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final skillCtrl = TextEditingController();

  final Color cardBlue = const Color(0xFFC8D4F0);
  final Color darkText = const Color(0xFF1F223D);
  final Color green = const Color(0xFFB8F2B8);

  Future<void> createPost() async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Request post created")));
      Navigator.pushReplacementNamed(context, '/post');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.errorMessage ?? 'Unable to create request.',
          ),
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
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        bottomNavigationBar: const BottomSidebar(currentIndex: 2),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Request Post",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Tell others what skill you need help with.",
                  style: TextStyle(
                    fontSize: 16,
                    color: darkText.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBlue,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      inputBox(
                        controller: titleCtrl,
                        label: "Post Title",
                        hint: "Example: Need help in Canva Design",
                        maxLines: 1,
                      ),

                      const SizedBox(height: 16),

                      inputBox(
                        controller: skillCtrl,
                        label: "Skill Needed",
                        hint: "Example: Canva, Flutter, Python",
                        maxLines: 1,
                      ),

                      const SizedBox(height: 16),

                      inputBox(
                        controller: descriptionCtrl,
                        label: "Description",
                        hint: "Describe what help you need...",
                        maxLines: 6,
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: widget.viewModel.isSubmitting
                              ? null
                              : createPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: darkText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: widget.viewModel.isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text(
                                  "Publish Request",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }

  Widget inputBox({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
