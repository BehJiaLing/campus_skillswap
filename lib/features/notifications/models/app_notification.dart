class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.postId,
    required this.postTitle,
    required this.message,
    required this.status,
    required this.isRead,
    this.createdAt,
    this.chatId,
  });

  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String type;
  final String postId;
  final String postTitle;
  final String message;
  final String status;
  final bool isRead;
  final DateTime? createdAt;
  final String? chatId;

  bool get isInvitation => type == 'helper_invitation';
  bool get isPending => status == 'pending';
}
