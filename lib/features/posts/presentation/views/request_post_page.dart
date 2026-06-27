import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../../models/request_post.dart';
import '../view_models/my_requests_view_model.dart';
import '../view_models/request_post_detail_view_model.dart';
import 'request_post_detail_page.dart';

class RequestPostPage extends StatelessWidget {
  const RequestPostPage({
    super.key,
    required this.viewModel,
    required this.detailViewModelBuilder,
  });

  final MyRequestsViewModel viewModel;
  final RequestPostDetailViewModel Function(String postId)
  detailViewModelBuilder;

  final Color cardBlue = const Color(0xFFC8D4F0);
  final Color darkText = const Color(0xFF1F223D);
  final Color green = const Color(0xFFB8F2B8);
  final Color peach = const Color(0xFFEFCFAB);

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isSignedIn) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Back to Login"),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomSidebar(currentIndex: 3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
              child: Row(
                children: [
                  Icon(Icons.notifications_rounded, size: 40, color: darkText),
                  const SizedBox(width: 14),
                  Text(
                    "My Requests",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<RequestPost>>(
                stream: viewModel.posts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Failed to load requests"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!;

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        "You have not created any request post yet",
                        style: TextStyle(fontSize: 17),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestPostDetailPage(
                                viewModel: detailViewModelBuilder(post.id),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
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
                                      post.title,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                  ),
                                  _statusBadge(post.status),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  post.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: darkText,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Date: ${formatDate(post.createdAt)}",
                                    style: TextStyle(color: darkText),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
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

  Widget _statusBadge(RequestPostStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: status == RequestPostStatus.open ? green : peach,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day}/${date.month}/${date.year}";
  }
}
