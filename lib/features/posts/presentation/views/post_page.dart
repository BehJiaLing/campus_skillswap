import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../../models/request_post.dart';
import '../view_models/post_feed_view_model.dart';
import '../view_models/request_post_detail_view_model.dart';
import 'request_post_detail_page.dart';

class PostPage extends StatelessWidget {
  const PostPage({
    super.key,
    required this.viewModel,
    required this.detailViewModelBuilder,
  });

  final PostFeedViewModel viewModel;
  final RequestPostDetailViewModel Function(String postId)
  detailViewModelBuilder;

  final Color bg = const Color(0xFFFFFFFF);
  final Color cardBlue = const Color(0xFFC8D4F0);
  final Color darkText = const Color(0xFF1F223D);
  final Color green = const Color(0xFFB8F2B8);
  final Color peach = const Color(0xFFEFCFAB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const BottomSidebar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: cardBlue,
                    child: Icon(Icons.school, size: 42, color: darkText),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back.",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        "How can we help you?",
                        style: TextStyle(fontSize: 20, color: darkText),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<RequestPost>>(
                stream: viewModel.posts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Failed to load posts"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!;

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        "No request posts yet",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestPostDetailPage(
                              viewModel: detailViewModelBuilder(post.id),
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      post.userName,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          post.status == RequestPostStatus.open
                                          ? green
                                          : peach,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      post.status.label,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: darkText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              Text(
                                post.course,
                                style: TextStyle(fontSize: 16, color: darkText),
                              ),

                              const SizedBox(height: 14),

                              Text(
                                post.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),

                              const SizedBox(height: 14),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                constraints: const BoxConstraints(
                                  minHeight: 110,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  post.description,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: darkText,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "Publish Date: ${formatDate(post.createdAt)}",
                                style: TextStyle(fontSize: 16, color: darkText),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day}/${date.month}/${date.year}";
  }
}
