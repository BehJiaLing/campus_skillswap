import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../chat/presentation/views/chat_detail_page.dart';
import '../../../../core/widgets/blocking_loading_overlay.dart';
import '../../models/ai_match.dart';
import '../../models/request_interactions.dart';
import '../../models/request_post.dart';
import '../../../profile/models/user_profile.dart';
import '../../../profile/presentation/views/user_profile_dialog.dart';
import '../view_models/request_post_detail_view_model.dart';
import 'all_helper_offers_page.dart';

class RequestPostDetailPage extends StatefulWidget {
  const RequestPostDetailPage({super.key, required this.viewModel});

  final RequestPostDetailViewModel viewModel;

  @override
  State<RequestPostDetailPage> createState() => _RequestPostDetailPageState();
}

class _RequestPostDetailPageState extends State<RequestPostDetailPage> {
  static const navy = Color(0xFF1A1F5E);
  static const darkText = Color(0xFF1F223D);
  static const bg = Color(0xFFF7F8FC);
  static const softBlue = Color(0xFFEAF2FF);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return BlockingLoadingOverlay(
          loading: widget.viewModel.busy,
          message: 'Updating request...',
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF4F7FB),
            appBar: AppBar(
              title: const Text('Request Details'),
              backgroundColor: navy,
              foregroundColor: Colors.white,
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

                if (post.isBanned && !widget.viewModel.isOwner(post)) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'This post has been banned and is unavailable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                return Scrollbar(
                  thumbVisibility: true,
                  thickness: 5,
                  radius: const Radius.circular(20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _requestHeader(post),
                        _section(
                          title: 'Status Progress',
                          icon: Icons.timeline_rounded,
                          child: _progress(post.status),
                        ),
                        if (widget.viewModel.isOwner(post) ||
                            post.pendingHelperId ==
                                widget.viewModel.currentUserId ||
                            post.matchedUserId != null)
                          _offers(post),
                        _actionArea(post),
                        _comments(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _requestHeader(RequestPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              post.isBanned ? _bannedBadge() : _badge(post.status),
              const Spacer(),
              if (widget.viewModel.isOwner(post))
                PopupMenuButton<String>(
                  color: Theme.of(context).cardColor,
                  iconColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') _showEditPostDialog(post);
                    if (value == 'delete') _confirmDeletePost(post);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Post'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete Post'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _infoPill(Icons.psychology_alt_rounded, 'Skill: ${post.skillNeeded}'),
          const SizedBox(height: 10),
          Text(
            post.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPostDialog(RequestPost post) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditPostDialog(
        post: post,
        onSave: (input) => widget.viewModel.updatePost(post, input),
        errorMessage: () => widget.viewModel.errorMessage,
      ),
    );
    if (saved == true) showResult(true, 'Post updated.');
  }

  Future<void> _confirmDeletePost(RequestPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'The post will disappear for users but remain recoverable by an administrator. Existing helper ratings and points will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await widget.viewModel.deletePost(post);
    if (!mounted) return;
    showResult(ok, 'Post moved to the recovery audit.');
    if (ok) Navigator.pop(context);
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.red.shade100,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.red),
    ),
    child: const Text(
      'BANNED',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    ),
  );

  Widget _actionArea(RequestPost post) {
    Widget? action;

    if (widget.viewModel.currentUserId != null &&
        !widget.viewModel.isOwner(post) &&
        post.status == RequestPostStatus.open) {
      action = StreamBuilder<List<HelpOffer>>(
        stream: widget.viewModel.offers,
        builder: (context, snapshot) {
          final sent = (snapshot.data ?? const <HelpOffer>[]).any(
            (offer) => offer.userId == widget.viewModel.currentUserId,
          );
          if (sent) {
            final onHold =
                post.pendingHelperId != null &&
                post.pendingHelperId != widget.viewModel.currentUserId;
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: onHold ? Colors.grey : Colors.green,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(
                  onHold ? Icons.hourglass_top_rounded : Icons.check_circle,
                ),
                label: Text(onHold ? 'Offer On Hold' : 'Offer Sent'),
              ),
            );
          }
          if (post.pendingHelperId != null) {
            return const SizedBox.shrink();
          }
          return _button('Offer Help', Icons.volunteer_activism, () async {
            showResult(
              await widget.viewModel.offerHelp(post),
              'Your offer was sent.',
            );
          });
        },
      );
    } else if (widget.viewModel.isOwner(post) &&
        post.status == RequestPostStatus.matched) {
      action = _button('End Post & Rate Helper', Icons.flag_circle_rounded, () {
        _showCompletionRatingDialog(post);
      });
    }

    if (action == null) return const SizedBox(height: 8);
    return Padding(padding: const EdgeInsets.only(top: 18), child: action);
  }

  Widget _aiMatchCard(
    AiMatch match, {
    required bool isTop,
    required int rank,
    VoidCallback? onChoose,
  }) {
    return GestureDetector(
      onTap: () => showUserProfileDialog(context, userId: match.userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTop ? const Color(0xFFFFC857) : const Color(0xFFE7EAF3),
            width: isTop ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTop)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Top AI Recommendation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A5A00),
                  ),
                ),
              ),
            Row(
              children: [
                _percentageCircle(match.matchPercentage),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$rank ${match.userName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(match.course),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _skillChips(match.skills),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: match.matchPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: _matchColor(match.matchPercentage),
              borderRadius: BorderRadius.circular(30),
            ),
            const SizedBox(height: 12),
            _reasonBox(match.reason),
            if (onChoose != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Choose This Helper'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _offers(RequestPost post) {
    if (post.pendingHelperId != null && post.pendingHelperName != null) {
      final isOwner = widget.viewModel.isOwner(post);
      final otherId = isOwner ? post.pendingHelperId! : post.userId;
      final otherName = isOwner ? post.pendingHelperName! : post.userName;
      return _section(
        title: isOwner ? 'Pending Helper Invitation' : 'Helper Invitation',
        icon: Icons.hourglass_top_rounded,
        child: FutureBuilder<UserProfile?>(
          future: widget.viewModel.getHelperProfile(otherId),
          builder: (context, snapshot) => _relationshipCard(
            post: post,
            profile: snapshot.data,
            name: otherName,
            otherUserId: otherId,
            message: isOwner
                ? 'Waiting for $otherName to accept or reject your invitation.'
                : '${post.userName} invited you to help with this request.',
            actions: isOwner
                ? [
                    OutlinedButton.icon(
                      onPressed: widget.viewModel.busy
                          ? null
                          : () async => showResult(
                              await widget.viewModel.cancelHelperInvitation(
                                post,
                              ),
                              'Helper invitation cancelled.',
                            ),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel Request'),
                    ),
                  ]
                : [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.viewModel.busy
                            ? null
                            : _rejectInvitationWithMessage,
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.viewModel.busy
                            ? null
                            : () async => showResult(
                                await widget.viewModel
                                    .respondToPendingInvitation(true),
                                'Invitation accepted. You are now matched.',
                              ),
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                      ),
                    ),
                  ],
          ),
        ),
      );
    }
    if (post.matchedUserId != null && post.matchedUserName != null) {
      final isOwner = widget.viewModel.isOwner(post);
      final isMatchedHelper =
          widget.viewModel.currentUserId == post.matchedUserId;
      final showRequester = !isOwner && isMatchedHelper;
      final otherId = showRequester ? post.userId : post.matchedUserId!;
      final otherName = showRequester ? post.userName : post.matchedUserName!;
      return _section(
        title: showRequester ? 'Matched Requester' : 'Confirmed Helper',
        icon: Icons.verified_user_rounded,
        child: FutureBuilder<UserProfile?>(
          future: widget.viewModel.getHelperProfile(otherId),
          builder: (context, snapshot) => Column(
            children: [
              _relationshipCard(
                post: post,
                profile: snapshot.data,
                name: otherName,
                otherUserId: otherId,
                message: '',
                allowChat: isOwner || isMatchedHelper,
              ),
              if (post.status == RequestPostStatus.completed)
                _finalRatingReview(post),
            ],
          ),
        ),
      );
    }
    return _section(
      title: 'Top Helper Offers',
      icon: Icons.people_alt_rounded,
      child: StreamBuilder<List<HelpOffer>>(
        stream: widget.viewModel.offers,
        builder: (context, snapshot) {
          final offers = [...(snapshot.data ?? const <HelpOffer>[])]
            ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

          if (offers.isEmpty) {
            return Column(
              children: [
                _emptyState(
                  icon: Icons.person_search_rounded,
                  title: 'No helper offers yet',
                  message: 'No helper offer? Use AI matching profile!!',
                ),
                const SizedBox(height: 14),
                _button(
                  'No helper offer? Use AI matching profile!!',
                  Icons.auto_awesome,
                  () => _showAiMatchingDialog(post, offers),
                ),
              ],
            );
          }

          final topOffers = offers.take(3).toList(growable: false);
          final rankingById = <String, AiMatch>{
            for (final item in widget.viewModel.rankedOffers) item.userId: item,
          };
          if (rankingById.isNotEmpty) {
            topOffers.sort(
              (a, b) => (rankingById[b.userId]?.matchPercentage ?? 0).compareTo(
                rankingById[a.userId]?.matchPercentage ?? 0,
              ),
            );
          }

          return Column(
            children: [
              if (offers.length >= 2) ...[
                _button(
                  'AI Rank Helper Offers',
                  Icons.leaderboard_rounded,
                  () => _showOfferRankingDialog(post, offers),
                ),
                const SizedBox(height: 8),
              ],
              if (offers.length > 3)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllHelperOffersPage(
                          post: post,
                          offers: offers,
                          viewModel: widget.viewModel,
                        ),
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Text('>>'),
                    label: Text('View all ${offers.length} helper offers'),
                  ),
                ),
              ...List.generate(
                topOffers.length,
                (index) => _offerCard(
                  post,
                  topOffers[index],
                  ranking: rankingById[topOffers[index].userId],
                  rank: rankingById.isEmpty ? null : index + 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "All don't want? Try AI matching profile!!",
                style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 8),
              _button(
                'Try AI Matching Profile',
                Icons.manage_search_rounded,
                () => _showAiMatchingDialog(post, offers),
                secondary: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rejectInvitationWithMessage() async {
    final controller = TextEditingController();
    final message = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Invitation'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message (optional)',
            hintText: 'Let the requester know why',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null) return;
    showResult(
      await widget.viewModel.respondToPendingInvitation(
        false,
        rejectionMessage: message,
      ),
      'Invitation rejected.',
    );
  }

  Widget _relationshipCard({
    required RequestPost post,
    required UserProfile? profile,
    required String name,
    required String otherUserId,
    required String message,
    bool allowChat = true,
    List<Widget> actions = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => showUserProfileDialog(context, userId: otherUserId),
              child: CircleAvatar(
                radius: 31,
                backgroundColor: softBlue,
                backgroundImage: profile?.photoUrl == null
                    ? null
                    : NetworkImage(profile!.photoUrl!),
                child: profile?.photoUrl == null
                    ? const Icon(Icons.person, color: navy, size: 33)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile != null) Text(profile.course),
                  if (profile != null)
                    Text(
                      '★ ${profile.averageRating.toStringAsFixed(1)}  •  ${profile.rewardPoints} points',
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (allowChat && post.chatId != null)
              IconButton.filled(
                tooltip: 'Message $name',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailPage(
                      userName: name,
                      chatId: post.chatId!,
                      otherUserId: otherUserId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.message_rounded),
              ),
          ],
        ),
        if (message.isNotEmpty &&
            profile != null &&
            profile.skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          _skillChips(profile.skills),
        ],
        if (message.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(children: actions),
        ],
      ],
    );
  }

  Widget _finalRatingReview(RequestPost post) {
    return StreamBuilder<List<RequestRating>>(
      stream: widget.viewModel.ratings,
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? const <RequestRating>[];
        final matching = ratings
            .where((rating) => rating.toUserId == post.matchedUserId)
            .toList();
        if (matching.isEmpty) return const SizedBox.shrink();
        final rating = matching.first;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Final Rating & Comment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${'★' * rating.stars}${'☆' * (5 - rating.stars)}',
                style: const TextStyle(color: Colors.amber, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                rating.review.isEmpty ? 'No written comment.' : rating.review,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _offerCard(
    RequestPost post,
    HelpOffer offer, {
    AiMatch? ranking,
    int? rank,
  }) {
    final accepted = offer.status == 'accepted';
    return GestureDetector(
      onTap: () => showUserProfileDialog(context, userId: offer.userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accepted ? Colors.green : const Color(0xFFE7EAF3),
            width: accepted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      showUserProfileDialog(context, userId: offer.userId),
                  child: ranking == null
                      ? const CircleAvatar(
                          radius: 29,
                          backgroundColor: softBlue,
                          child: Icon(Icons.person, color: navy, size: 31),
                        )
                      : _percentageCircle(ranking.matchPercentage),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rank == null ? '' : '#$rank '}${offer.userName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        offer.course,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (accepted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 30),
              ],
            ),
            if (ranking != null) ...[
              const SizedBox(height: 14),
              _skillChips(offer.skills),
              const SizedBox(height: 12),
              _reasonBox(ranking.reason),
            ],
            if (post.status == RequestPostStatus.open && !accepted) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.viewModel.busy
                      ? null
                      : () async => showResult(
                          await widget.viewModel.acceptCandidate(
                            post,
                            helperId: offer.userId,
                            helperName: offer.userName,
                          ),
                          '${offer.userName} has been selected as the helper.',
                        ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Choose This Helper'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showOfferRankingDialog(
    RequestPost post,
    List<HelpOffer> offers,
  ) async {
    final ranking = widget.viewModel.rankHelperOffers(post, offers);
    await _showBlurredDialog(
      title: 'AI Best Helper Offers',
      child: FutureBuilder<bool>(
        future: ranking,
        builder: (dialogContext, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _dialogLoading('Groq is ranking all helper offers...');
          }
          if (snapshot.data != true) {
            return _dialogError(widget.viewModel.errorMessage);
          }
          final ranked = widget.viewModel.rankedOffers.take(3).toList();
          if (ranked.isEmpty) {
            return _dialogError('Groq did not return a valid helper ranking.');
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              ranked.length,
              (index) => _aiMatchCard(
                ranked[index],
                isTop: index == 0,
                rank: index + 1,
                onChoose: post.status == RequestPostStatus.open
                    ? () => _chooseCandidate(dialogContext, post, ranked[index])
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCompletionRatingDialog(RequestPost post) async {
    selectedStars = 5;
    reviewController.clear();
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Finish this skill exchange'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate your helper. The rating also awards 20 points per star.',
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: saving
                        ? null
                        : () => setDialogState(() => selectedStars = index + 1),
                    icon: Icon(
                      index < selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: reviewController,
                enabled: !saving,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final ok = await widget.viewModel.submitRating(
                        post,
                        selectedStars,
                        reviewController.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (ok) Navigator.pop(dialogContext);
                      if (!ok) setDialogState(() => saving = false);
                      showResult(ok, 'Post completed and helper rating saved.');
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Complete Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiMatchingDialog(
    RequestPost post,
    List<HelpOffer> offers,
  ) async {
    _combinedRankingVisible[post.id] = false;
    final matching = widget.viewModel.generateAiMatches(post);
    await _showBlurredDialog(
      title: 'AI Matching Profiles',
      child: FutureBuilder<bool>(
        future: matching,
        builder: (dialogContext, futureSnapshot) {
          if (futureSnapshot.connectionState != ConnectionState.done) {
            return _dialogLoading(
              'Rule-based filtering is selecting 5 profiles, then Groq will rank the best 3...',
            );
          }
          if (futureSnapshot.data != true) {
            return _dialogError(widget.viewModel.errorMessage);
          }

          return StreamBuilder<List<AiMatch>>(
            stream: widget.viewModel.aiMatches,
            builder: (context, matchSnapshot) {
              final matches = [
                ...(matchSnapshot.data ?? const <AiMatch>[]),
              ]..sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
              if (matches.isEmpty) {
                return _dialogError('No suitable profiles were found.');
              }

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  var combinedVisible =
                      _combinedRankingVisible[post.id] ?? false;
                  final combined = _combineCandidates(
                    matches,
                    offers,
                  ).take(3).toList(growable: false);
                  final displayed = combinedVisible
                      ? combined
                            .map(
                              (candidate) => AiMatch(
                                userId: candidate.userId,
                                userName: candidate.userName,
                                course: candidate.course,
                                skills: candidate.skills,
                                matchPercentage: candidate.finalScore,
                                reason: candidate.reason,
                              ),
                            )
                            .toList(growable: false)
                      : matches.take(3).toList(growable: false);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (combinedVisible)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Final Combined Ranking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                        ),
                      ...List.generate(
                        displayed.length,
                        (index) => _aiMatchCard(
                          displayed[index],
                          isTop: index == 0,
                          rank: index + 1,
                          onChoose: post.status == RequestPostStatus.open
                              ? () => _chooseCandidate(
                                  dialogContext,
                                  post,
                                  displayed[index],
                                )
                              : null,
                        ),
                      ),
                      if (offers.isNotEmpty && !combinedVisible) ...[
                        const SizedBox(height: 6),
                        _button(
                          'Combine Final Ranking',
                          Icons.merge_rounded,
                          () {
                            _combinedRankingVisible[post.id] = true;
                            setDialogState(() {
                              combinedVisible = true;
                            });
                          },
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  final Map<String, bool> _combinedRankingVisible = {};

  Future<void> _chooseCandidate(
    BuildContext dialogContext,
    RequestPost post,
    AiMatch candidate,
  ) async {
    final success = await widget.viewModel.acceptCandidate(
      post,
      helperId: candidate.userId,
      helperName: candidate.userName,
    );
    if (!mounted || !dialogContext.mounted) return;
    showResult(
      success,
      'Helper selection updated. If needed, an invitation is now waiting for reply.',
    );
    if (success) Navigator.pop(dialogContext);
  }

  Future<void> _showBlurredDialog({
    required String title,
    required Widget child,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close AI matching',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.sizeOf(dialogContext).width * 0.92,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.86,
                    maxWidth: 560,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 10, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: navy),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Widget _dialogLoading(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 18),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _dialogError(String? message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
        const SizedBox(height: 12),
        Text(
          message ?? 'Unable to generate ranking. Please try again.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _comments() {
    return _section(
      title: 'Comments',
      icon: Icons.mode_comment_rounded,
      child: Column(
        children: [
          StreamBuilder<List<RequestComment>>(
            stream: widget.viewModel.comments,
            builder: (context, snapshot) {
              final comments = snapshot.data ?? const [];

              if (comments.isEmpty) {
                return _emptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No comments yet',
                  message: 'Start a discussion about this request.',
                );
              }

              return Column(
                children: comments.map((comment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7EAF3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => showUserProfileDialog(
                            context,
                            userId: comment.userId,
                          ),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: softBlue,
                            child: Icon(Icons.person, color: navy, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(comment.message),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: navy),
                onPressed: widget.viewModel.commentBusy
                    ? null
                    : () async {
                        final success = await widget.viewModel.addComment(
                          commentController.text,
                        );
                        if (success) commentController.clear();
                        showResult(success, 'Comment added.');
                      },
                icon: widget.viewModel.commentBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Legacy renderer retained for old completed records; it is intentionally not
  // displayed because new ratings are collected only by the End Post action.
  // ignore: unused_element
  Widget _ratings(RequestPost post) {
    return _section(
      title: 'Rating & Review',
      icon: Icons.star_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<RequestRating>>(
            stream: widget.viewModel.ratings,
            builder: (context, snapshot) {
              final ratings = snapshot.data ?? const [];

              if (ratings.isEmpty) {
                return _emptyState(
                  icon: Icons.star_border_rounded,
                  title: 'No ratings yet',
                  message: 'Ratings will appear after the skill exchange ends.',
                );
              }

              return Column(
                children: ratings.map((rating) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7EAF3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '★' * rating.stars,
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rating.review.isEmpty
                              ? 'No written review'
                              : rating.review,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (post.status == RequestPostStatus.completed &&
              (widget.viewModel.currentUserId == post.userId ||
                  widget.viewModel.currentUserId == post.matchedUserId)) ...[
            const Divider(height: 28),
            const Text(
              'Leave your review',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () => setState(() => selectedStars = star),
                  icon: Icon(
                    star <= selectedStars ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade700,
                    size: 30,
                  ),
                );
              }),
            ),
            TextField(
              controller: reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: navy, size: 23),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _card(child: child),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _badge(RequestPostStatus status) {
    final color = switch (status) {
      RequestPostStatus.open => green,
      RequestPostStatus.matched => peach,
      RequestPostStatus.inProgress => peach,
      RequestPostStatus.completed => const Color(0xFFD1D5DB),
      RequestPostStatus.cancelled => const Color(0xFFD1D5DB),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(fontWeight: FontWeight.bold, color: darkText),
      ),
    );
  }

  Widget _progress(RequestPostStatus status) {
    final step = switch (status) {
      RequestPostStatus.open => 0,
      RequestPostStatus.matched => 1,
      RequestPostStatus.inProgress => 1,
      RequestPostStatus.completed => 2,
      RequestPostStatus.cancelled => 0,
    };

    const labels = ['Open', 'Matched', 'Done'];
    const icons = [
      Icons.radio_button_checked,
      Icons.people,
      Icons.check_circle,
    ];

    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= step;

        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: active ? navy : const Color(0xFFE8ECF5),
                child: Icon(
                  icons[index],
                  size: 18,
                  color: active ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? green : const Color(0xFFE8ECF5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? darkText : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _percentageCircle(int percentage) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _matchColor(percentage).withValues(alpha: 0.13),
        border: Border.all(color: _matchColor(percentage), width: 2),
      ),
      child: Center(
        child: Text(
          '$percentage%',
          style: TextStyle(
            color: _matchColor(percentage),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _skillChips(List<String> skills) {
    if (skills.isEmpty) {
      return const Text(
        'No skills listed',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            skill,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _reasonBox(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Text(
        reason,
        style: const TextStyle(fontSize: 14, height: 1.4, color: darkText),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.grey.shade600),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _matchColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 65) return Colors.orange;
    return Colors.redAccent;
  }

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

  List<FinalCandidate> _combineCandidates(
    List<AiMatch> aiMatches,
    List<HelpOffer> offers,
  ) {
    final Map<String, FinalCandidate> result = {};

    for (final ai in aiMatches) {
      result[ai.userId] = FinalCandidate(
        userId: ai.userId,
        userName: ai.userName,
        course: ai.course,
        skills: ai.skills,
        finalScore: ai.matchPercentage,
        reason: ai.reason,
        isAiSuggested: true,
        isOfferHelper: false,
        status: 'pending',
      );
    }

    for (final offer in offers) {
      final existing = result[offer.userId];

      if (existing != null) {
        final combinedScore =
            ((existing.finalScore * 0.6) + (offer.matchScore * 0.4) + 8)
                .round()
                .clamp(0, 100);

        result[offer.userId] = FinalCandidate(
          userId: offer.userId,
          userName: offer.userName,
          course: offer.course,
          skills: offer.skills.isNotEmpty ? offer.skills : existing.skills,
          finalScore: combinedScore,
          reason:
              '${existing.reason} This student also offered help, making this a stronger candidate.',
          isAiSuggested: true,
          isOfferHelper: true,
          status: offer.status,
        );
      } else {
        result[offer.userId] = FinalCandidate(
          userId: offer.userId,
          userName: offer.userName,
          course: offer.course,
          skills: offer.skills,
          finalScore: offer.matchScore,
          reason: _matchReason(offer),
          isAiSuggested: false,
          isOfferHelper: true,
          status: offer.status,
        );
      }
    }

    final list = result.values.toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return list;
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
          backgroundColor: secondary
              ? Theme.of(context).colorScheme.surface
              : navy,
          foregroundColor: secondary
              ? Theme.of(context).colorScheme.onSurface
              : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: secondary ? const BorderSide(color: navy) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _EditPostDialog extends StatefulWidget {
  const _EditPostDialog({
    required this.post,
    required this.onSave,
    required this.errorMessage,
  });

  final RequestPost post;
  final Future<bool> Function(UpdateRequestPostInput input) onSave;
  final String? Function() errorMessage;

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final TextEditingController _title;
  late final TextEditingController _skill;
  late final TextEditingController _description;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.post.title);
    _skill = TextEditingController(text: widget.post.skillNeeded);
    _description = TextEditingController(text: widget.post.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _skill.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(
      UpdateRequestPostInput(
        title: _title.text,
        skillNeeded: _skill.text,
        description: _description.text,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = widget.errorMessage() ?? 'Unable to update the post.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Post name'),
            ),
            TextField(
              controller: _skill,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Skill needed'),
            ),
            TextField(
              controller: _description,
              enabled: !_saving,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class FinalCandidate {
  const FinalCandidate({
    required this.userId,
    required this.userName,
    required this.course,
    required this.skills,
    required this.finalScore,
    required this.reason,
    required this.isAiSuggested,
    required this.isOfferHelper,
    required this.status,
  });

  final String userId;
  final String userName;
  final String course;
  final List<String> skills;
  final int finalScore;
  final String reason;
  final bool isAiSuggested;
  final bool isOfferHelper;
  final String status;
}
