import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../../../../core/widgets/blocking_loading_overlay.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';
import '../../../posts/presentation/view_models/request_post_detail_view_model.dart';
import '../../../posts/presentation/views/request_post_detail_page.dart';
import '../../../chat/presentation/views/chat_detail_page.dart';
import '../../models/app_notification.dart';
import '../view_models/notification_view_model.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({
    super.key,
    required this.viewModel,
    required this.detailViewModelBuilder,
  });

  final NotificationViewModel viewModel;
  final RequestPostDetailViewModel Function(String postId)
  detailViewModelBuilder;
  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => BlockingLoadingOverlay(
        loading: viewModel.busy,
        message: 'Updating invitation...',
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF4F7FB),
          bottomNavigationBar: const BottomSidebar(currentIndex: 3),
          body: SafeArea(
            child: Column(
              children: [
                const SkillSwapPageHeader(
                  title: 'Notifications',
                  subtitle: 'Offers, matches, comments and account updates.',
                ),
                Expanded(
                  child: StreamBuilder<List<AppNotification>>(
                    stream: viewModel.notifications,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Failed to load notifications'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final notifications = snapshot.data!;
                      if (notifications.isEmpty) {
                        return const Center(
                          child: Text('No notifications yet'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) =>
                            _card(context, notifications[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppNotification item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: item.isRead
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFEAF2FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: item.isRead
              ? Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .6)
              : navy.withValues(alpha: .18),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await viewModel.markRead(item.id);
          if (!context.mounted) return;
          if (item.type == 'chat_message' && item.chatId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  userName: item.senderName,
                  chatId: item.chatId!,
                  otherUserId: item.senderId,
                ),
              ),
            );
            return;
          }
          if (item.postId.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestPostDetailPage(
                viewModel: detailViewModelBuilder(item.postId),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _color(item.status).withValues(alpha: .15),
                    child: Icon(_icon(item.type), color: _color(item.status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.postTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item.message),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: navy),
                ],
              ),
              if (item.isInvitation && item.isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: viewModel.busy
                            ? null
                            : () => _respond(context, item, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: viewModel.busy
                            ? null
                            : () => _respond(context, item, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: FilledButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (item.status != 'info') ...[
                const SizedBox(height: 10),
                Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: _color(item.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    AppNotification item,
    bool accepted,
  ) async {
    String? rejectionMessage;
    if (!accepted) {
      final controller = TextEditingController();
      rejectionMessage = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Invitation'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
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
      if (rejectionMessage == null) return;
    }
    final ok = await viewModel.respond(
      item,
      accepted,
      rejectionMessage: rejectionMessage,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? accepted
                    ? 'Invitation accepted. The request is now matched.'
                    : 'Invitation declined.'
              : viewModel.errorMessage ?? 'Unable to respond.',
        ),
        backgroundColor: ok && accepted ? const Color(0xFF12A875) : Colors.red,
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'helper_invitation' => Icons.person_add_alt_1,
    'helper_offer' => Icons.volunteer_activism,
    'offer_accepted' || 'invitation_accepted' => Icons.check_circle,
    'invitation_rejected' => Icons.cancel,
    'rating_received' => Icons.star_rounded,
    'chat_message' => Icons.chat_bubble_rounded,
    'post_comment' => Icons.comment_rounded,
    'post_status' => Icons.track_changes_rounded,
    'post_banned' => Icons.block_rounded,
    'post_unbanned' => Icons.restore_rounded,
    'post_restored' => Icons.restore_from_trash_rounded,
    'post_deleted' => Icons.delete_outline_rounded,
    'offer_on_hold' => Icons.hourglass_top_rounded,
    _ => Icons.notifications,
  };

  Color _color(String status) => switch (status) {
    'accepted' => Colors.green,
    'rejected' => Colors.redAccent,
    'pending' => Colors.orange,
    _ => const Color(0xFF1A1F5E),
  };
}
