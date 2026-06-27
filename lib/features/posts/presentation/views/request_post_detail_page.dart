import 'package:flutter/material.dart';

import '../../../chat/presentation/views/chat_detail_page.dart';
import '../../models/request_interactions.dart';
import '../../models/request_post.dart';
import '../view_models/request_post_detail_view_model.dart';

class RequestPostDetailPage extends StatefulWidget {
  const RequestPostDetailPage({super.key, required this.viewModel});

  final RequestPostDetailViewModel viewModel;

  @override
  State<RequestPostDetailPage> createState() => _RequestPostDetailPageState();
}

class _RequestPostDetailPageState extends State<RequestPostDetailPage> {
  static const cardBlue = Color(0xFFC8D4F0);
  static const darkText = Color(0xFF1F223D);
  static const green = Color(0xFFB8F2B8);
  static const peach = Color(0xFFEFCFAB);

  final commentController = TextEditingController();
  final reviewController = TextEditingController();
  int selectedStars = 5;

  @override
  void dispose() {
    commentController.dispose();
    reviewController.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  void showResult(bool success, String successMessage) {
    if (!mounted) return;
    final message = success
        ? successMessage
        : widget.viewModel.errorMessage ?? 'Something went wrong.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Request Details'),
          backgroundColor: Colors.white,
          foregroundColor: darkText,
          elevation: 0,
        ),
        body: StreamBuilder<RequestPost?>(
          stream: widget.viewModel.post,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load request'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final post = snapshot.data;

            if (post == null) {
              return const Center(child: Text('Post not found'));
            }

            return Scrollbar(
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _requestCard(post),
                    _section('Status Progress', _progress(post.status)),
                    _actionArea(post),
                    if (widget.viewModel.isOwner(post)) _offers(post),
                    _comments(),
                    _ratings(post),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _requestCard(RequestPost post) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ),
            _badge(post.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Skill needed: ${post.skillNeeded}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          post.description,
          style: const TextStyle(fontSize: 16, color: darkText),
        ),
        if (post.matchedUserName != null) ...[
          const SizedBox(height: 14),
          Text(
            'Matched helper: ${post.matchedUserName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ],
    ),
  );

  Widget _actionArea(RequestPost post) {
    Widget? action;

    if (widget.viewModel.canOffer(post)) {
      action = _button('Offer Help', Icons.volunteer_activism, () async {
        showResult(
          await widget.viewModel.offerHelp(post),
          'Your offer was sent.',
        );
      });
    } else if (widget.viewModel.isOwner(post) &&
        (post.status == RequestPostStatus.matched ||
            post.status == RequestPostStatus.inProgress)) {
      final label = post.status == RequestPostStatus.matched
          ? 'Start Skill Exchange'
          : 'Mark as Completed';

      action = _button(label, Icons.check_circle_outline, () async {
        showResult(
          await widget.viewModel.advanceStatus(post),
          'Request status updated.',
        );
      });
    }

    final canOpenChat = post.chatId != null &&
        (widget.viewModel.currentUserId == post.userId ||
            widget.viewModel.currentUserId == post.matchedUserId);

    if (action == null && !canOpenChat) return const SizedBox(height: 4);

    final actions = <Widget>[];

    if (action != null) actions.add(action);
    if (action != null && canOpenChat) actions.add(const SizedBox(height: 10));

    if (canOpenChat) {
      actions.add(
        _button(
          'Open Chat',
          Icons.chat_bubble_outline,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  userName: widget.viewModel.isOwner(post)
                      ? post.matchedUserName ?? 'Matched Helper'
                      : post.userName,
                  chatId: post.chatId!,
                  otherUserId: widget.viewModel.isOwner(post)
                      ? post.matchedUserId!
                      : post.userId,
                ),
              ),
            );
          },
          secondary: true,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(children: actions),
    );
  }

  Widget _offers(RequestPost post) => _section(
    'AI Matching Suggestion',
    StreamBuilder<List<HelpOffer>>(
      stream: widget.viewModel.offers,
      builder: (context, snapshot) {
        final offers = snapshot.data ?? const [];

        if (offers.isEmpty) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 36),
              SizedBox(height: 10),
              Text(
                'No matching helper yet.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'When students offer help, the system will suggest the best match based on skill, course, and match score.',
              ),
            ],
          );
        }

        final sortedOffers = [...offers]
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

        return Column(
          children: sortedOffers.map((offer) {
            final isBest = offer == sortedOffers.first;
            final isAccepted = offer.status == 'accepted';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isBest ? green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBest)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Best AI Match',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cardBlue,
                        child: Text(
                          '${offer.matchScore}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              offer.course,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (isAccepted)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 30,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Skills: ${offer.skills.join(', ')}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: offer.matchScore / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: offer.matchScore >= 80
                        ? Colors.green
                        : offer.matchScore >= 60
                        ? Colors.orange
                        : Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _matchReason(offer),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (post.status == RequestPostStatus.open &&
                      offer.status != 'accepted') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.viewModel.busy
                            ? null
                            : () async => showResult(
                          await widget.viewModel.acceptOffer(
                            post,
                            offer,
                          ),
                          '${offer.userName} was accepted.',
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Accept Helper'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    ),
  );

  String _matchReason(HelpOffer offer) {
    if (offer.matchScore >= 90) {
      return 'Strong match: this helper has related skills and is from the same course.';
    } else if (offer.matchScore >= 80) {
      return 'Good match: this helper has the skill needed for this request.';
    } else if (offer.matchScore >= 60) {
      return 'Moderate match: this helper may be suitable, but skill/course match is not perfect.';
    } else {
      return 'Low match: this helper can offer help, but may not fully match the request.';
    }
  }

  Widget _comments() => _section(
    'Comments',
    Column(
      children: [
        StreamBuilder<List<RequestComment>>(
          stream: widget.viewModel.comments,
          builder: (context, snapshot) {
            final comments = snapshot.data ?? const [];

            if (comments.isEmpty) return const Text('No comments yet.');

            return Column(
              children: comments
                  .map(
                    (comment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(comment.userName),
                  subtitle: Text(comment.message),
                ),
              )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Write a comment',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: widget.viewModel.busy
                  ? null
                  : () async {
                final success = await widget.viewModel.addComment(
                  commentController.text,
                );
                if (success) commentController.clear();
                showResult(success, 'Comment added.');
              },
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _ratings(RequestPost post) => _section(
    'Rating & Review',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<RequestRating>>(
          stream: widget.viewModel.ratings,
          builder: (context, snapshot) {
            final ratings = snapshot.data ?? const [];

            if (ratings.isEmpty) return const Text('No ratings yet.');

            return Column(
              children: ratings
                  .map(
                    (rating) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    '${rating.stars} ★',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  title: Text(
                    rating.review.isEmpty
                        ? 'No written review'
                        : rating.review,
                  ),
                ),
              )
                  .toList(),
            );
          },
        ),
        if (post.status == RequestPostStatus.completed &&
            (widget.viewModel.currentUserId == post.userId ||
                widget.viewModel.currentUserId == post.matchedUserId)) ...[
          const Divider(height: 28),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => selectedStars = star),
                icon: Icon(
                  star <= selectedStars ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                ),
              );
            }),
          ),
          TextField(
            controller: reviewController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your experience',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _button('Submit Rating', Icons.star, () async {
            final success = await widget.viewModel.submitRating(
              post,
              selectedStars,
              reviewController.text,
            );
            if (success) reviewController.clear();
            showResult(success, 'Rating submitted.');
          }),
        ],
      ],
    ),
  );

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 10),
        _card(child: child),
      ],
    ),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cardBlue,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _badge(RequestPostStatus status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: status == RequestPostStatus.open ? green : peach,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  Widget _progress(RequestPostStatus status) {
    final step = switch (status) {
      RequestPostStatus.open => 0,
      RequestPostStatus.matched => 1,
      RequestPostStatus.inProgress => 2,
      RequestPostStatus.completed => 3,
      RequestPostStatus.cancelled => 0,
    };

    const labels = ['Open', 'Matched', 'Progress', 'Done'];

    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= step;

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                labels[index],
                style: TextStyle(
                  fontWeight: active ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _button(
      String label,
      IconData icon,
      VoidCallback onPressed, {
        bool secondary = false,
      }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.viewModel.busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: secondary ? Colors.white : const Color(0xFF1A1F5E),
          foregroundColor: secondary ? darkText : Colors.white,
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}