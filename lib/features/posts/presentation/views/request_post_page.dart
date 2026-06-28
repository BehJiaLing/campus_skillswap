import 'package:flutter/material.dart';

import '../../../../core/widgets/skill_swap_page_header.dart';
import '../../models/request_post.dart';
import '../view_models/helper_posts_view_model.dart';
import '../view_models/my_requests_view_model.dart';
import '../view_models/request_post_detail_view_model.dart';
import 'request_post_detail_page.dart';

class MyPostsPage extends StatelessWidget {
  MyPostsPage({
    super.key,
    required MyRequestsViewModel viewModel,
    required this.detailViewModelBuilder,
  }) : posts = viewModel.posts,
       isSignedIn = viewModel.isSignedIn,
       pageTitle = 'My Posts',
       subtitle = 'Track and manage every request you created.',
       emptyMessage = 'You have not created a request yet.';

  MyPostsPage.helper({
    super.key,
    required HelperPostsViewModel viewModel,
    required this.detailViewModelBuilder,
  }) : posts = viewModel.posts,
       isSignedIn = viewModel.isSignedIn,
       pageTitle = 'Helper Posts',
       subtitle = 'Skill exchanges where you are the confirmed helper.',
       emptyMessage = 'You are not a confirmed helper for any post yet.';

  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);
  final Stream<List<RequestPost>>? posts;
  final bool isSignedIn;
  final String pageTitle;
  final String subtitle;
  final String emptyMessage;
  final RequestPostDetailViewModel Function(String postId)
  detailViewModelBuilder;

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
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
      body: SafeArea(
        child: Column(
          children: [
            SkillSwapPageHeader(
              title: pageTitle,
              subtitle: subtitle,
              trailing: IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RequestPost>>(
                stream: posts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load requests'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: green),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 52,
                              color: green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              emptyMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _postCard(context, items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postCard(BuildContext context, RequestPost post) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestPostDetailPage(
              viewModel: detailViewModelBuilder(post.id),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _status(post),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: navy.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.skillNeeded,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                post.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _date(post.createdAt),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: navy),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(RequestPost post) {
    final (label, color) = post.isDeleted
        ? ('DELETED', Colors.red)
        : post.isBanned
        ? ('BANNED', Colors.red)
        : switch (post.status) {
            RequestPostStatus.open => ('OPEN', green),
            RequestPostStatus.matched ||
            RequestPostStatus.inProgress => ('MATCHED', Colors.orange),
            RequestPostStatus.completed ||
            RequestPostStatus.cancelled => ('DONE', Colors.grey),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  String _date(DateTime? date) =>
      date == null ? '-' : '${date.day}/${date.month}/${date.year}';
}
