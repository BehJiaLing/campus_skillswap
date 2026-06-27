import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sidebar.dart';
import '../../../../core/widgets/blocking_loading_overlay.dart';
import '../../../posts/presentation/view_models/request_post_detail_view_model.dart';
import '../../../posts/presentation/views/request_post_detail_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => BlockingLoadingOverlay(
        loading: viewModel.busy,
        message: 'Updating invitation...',
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          bottomNavigationBar: const BottomSidebar(currentIndex: 3),
          body: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 24, 22, 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_rounded,
                        size: 36,
                        color: Color(0xFF1A1F5E),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
      color: item.isRead ? Colors.white : const Color(0xFFEAF2FF),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await viewModel.markRead(item.id);
          if (!context.mounted || item.postId.isEmpty) return;
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
                  const Icon(Icons.chevron_right),
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
    final ok = await viewModel.respond(item, accepted);
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
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'helper_invitation' => Icons.person_add_alt_1,
    'helper_offer' => Icons.volunteer_activism,
    'offer_accepted' || 'invitation_accepted' => Icons.check_circle,
    'invitation_rejected' => Icons.cancel,
    'rating_received' => Icons.star_rounded,
    _ => Icons.notifications,
  };

  Color _color(String status) => switch (status) {
    'accepted' => Colors.green,
    'rejected' => Colors.redAccent,
    'pending' => Colors.orange,
    _ => const Color(0xFF1A1F5E),
  };
}
