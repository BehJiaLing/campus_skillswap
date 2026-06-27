import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuditTrackPage extends StatefulWidget {
  const AdminAuditTrackPage({super.key});

  @override
  State<AdminAuditTrackPage> createState() => _AdminAuditTrackPageState();
}

class _AdminAuditTrackPageState extends State<AdminAuditTrackPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);
  final Color red = const Color(0xFFE53935);
  final Color orange = const Color(0xFFFF9800);

  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkBorder = const Color(0xFF374151);
  final Color darkField = const Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchText = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty) return fallback;
    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    }

    return value.toString();
  }

  String _skillsText(dynamic value) {
    if (value == null) return 'No skills';

    if (value is List) {
      if (value.isEmpty) return 'No skills';
      return value.map((e) => e.toString()).join(', ');
    }

    final text = value.toString().trim();
    if (text.isEmpty) return 'No skills';

    return text;
  }

  Map<String, dynamic> _originalData(Map<String, dynamic> data) {
    final originalData = data['originalData'];
    if (originalData is Map) {
      return Map<String, dynamic>.from(originalData);
    }
    return {};
  }

  bool _matchesSearch(List<String> values) {
    if (_searchText.isEmpty) return true;

    return values.any((value) {
      return value.toLowerCase().contains(_searchText);
    });
  }

  Future<void> _restoreUser({
    required String deletedDocId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final currentAdmin = FirebaseAuth.instance.currentUser;

      final userId = _text(
        data['deletedUserUid'] ??
            data['deletedUserId'] ??
            data['uid'] ??
            data['userId'],
        fallback: '',
      );

      if (userId.isEmpty) {
        throw 'Missing original user UID. Cannot restore user.';
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'uid': userId,
        'name': _text(data['deletedUserName'], fallback: 'No Name'),
        'email': _text(data['deletedUserEmail'], fallback: 'No Email'),
        'campus': _text(data['deletedUserCampus'], fallback: 'INTI'),
        'course': _text(data['deletedUserCourse'], fallback: ''),
        'skills': data['deletedUserSkills'] ?? [],
        'role': data['deletedUserRole'] ?? 'user',
        'status': 'active',
        'isSuspended': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByEmail': currentAdmin?.email ?? 'Unknown Admin',
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('deleted_users_history')
          .doc(deletedDocId)
          .update({
        'isRestored': true,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByEmail': currentAdmin?.email ?? 'Unknown Admin',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreDeletedPost({
    required String deletedDocId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final currentAdmin = FirebaseAuth.instance.currentUser;
      final originalPostData = _originalData(data);

      final postId = _text(
        data['postId'] ??
            data['deletedPostId'] ??
            data['originalPostId'] ??
            originalPostData['postId'] ??
            originalPostData['id'],
        fallback: '',
      );

      if (postId.isEmpty) {
        throw 'Missing original post ID. Cannot restore post.';
      }

      final restoredData = <String, dynamic>{
        ...originalPostData,
        ...data,
      };

      restoredData.remove('originalData');
      restoredData.remove('deletedAt');
      restoredData.remove('deletedByEmail');
      restoredData.remove('deletedByUid');
      restoredData.remove('isRestored');

      restoredData['status'] = 'active';
      restoredData['isBanned'] = false;
      restoredData['banned'] = false;
      restoredData['restoredAt'] = FieldValue.serverTimestamp();
      restoredData['restoredByEmail'] = currentAdmin?.email ?? 'Unknown Admin';
      restoredData['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .set(restoredData, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('deleted_posts_history')
          .doc(deletedDocId)
          .update({
        'isRestored': true,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByEmail': currentAdmin?.email ?? 'Unknown Admin',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore post failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unbanPost(String postId) async {
    try {
      final currentAdmin = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'status': 'active',
        'isBanned': false,
        'banned': false,
        'banReason': null,
        'bannedAt': null,
        'bannedByEmail': null,
        'bannedByUid': null,
        'unbannedAt': FieldValue.serverTimestamp(),
        'unbannedByEmail': currentAdmin?.email ?? 'Unknown Admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post unbanned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unban failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmRestoreUser({
    required String deletedDocId,
    required Map<String, dynamic> data,
  }) async {
    final name = _text(data['deletedUserName'], fallback: 'this user');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore User'),
          content: Text('Are you sure you want to restore $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.restore),
              label: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _restoreUser(deletedDocId: deletedDocId, data: data);
    }
  }

  Future<void> _confirmRestorePost({
    required String deletedDocId,
    required Map<String, dynamic> data,
  }) async {
    final originalPostData = _originalData(data);
    final title = _text(
      data['title'] ?? originalPostData['title'],
      fallback: 'this post',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Post'),
          content: Text('Are you sure you want to restore "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.restore),
              label: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _restoreDeletedPost(deletedDocId: deletedDocId, data: data);
    }
  }

  Future<void> _confirmUnbanPost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    final title = _text(data['title'], fallback: 'this post');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unban Post'),
          content: Text('Are you sure you want to unban "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.lock_open),
              label: const Text('Unban'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _unbanPost(postId);
    }
  }

  bool _matchesUserSearch(Map<String, dynamic> data) {
    return _matchesSearch([
      _text(data['deletedUserName']),
      _text(data['deletedUserEmail']),
      _text(data['deletedUserCampus']),
      _text(data['deletedUserCourse']),
      _skillsText(data['deletedUserSkills']),
      _text(data['deletedByEmail']),
    ]);
  }

  bool _matchesDeletedPostSearch(Map<String, dynamic> data) {
    final originalPostData = _originalData(data);

    return _matchesSearch([
      _text(data['title'] ?? originalPostData['title']),
      _text(data['description'] ?? originalPostData['description']),
      _text(data['postedBy'] ?? originalPostData['postedBy']),
      _text(data['course'] ?? originalPostData['course']),
      _skillsText(data['skills'] ?? originalPostData['skills']),
      _text(data['deletedByEmail']),
    ]);
  }

  bool _matchesBannedPostSearch(Map<String, dynamic> data) {
    return _matchesSearch([
      _text(data['title']),
      _text(data['description']),
      _text(data['postedBy'] ?? data['userEmail']),
      _text(data['course']),
      _skillsText(data['skills'] ?? data['skillNeeded']),
      _text(data['bannedByEmail']),
      _text(data['banReason']),
    ]);
  }

  Widget _statusChip({
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _sectionBox({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: subTextColor),
          ),
          const SizedBox(height: 16),
          Divider(color: lineColor),
          child,
        ],
      ),
    );
  }

  Widget _searchBox({required bool isDark}) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;
    final lineColor = isDark ? darkBorder : border;
    final fieldColor = isDark ? darkField : bg;

    return TextField(
      controller: _searchCtrl,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: 'Search users, posts, email, course or skill...',
        hintStyle: TextStyle(fontSize: 13, color: subTextColor),
        prefixIcon: Icon(Icons.search, size: 20, color: subTextColor),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, size: 18, color: subTextColor),
          onPressed: () {
            _searchCtrl.clear();
          },
        )
            : null,
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF818CF8) : navy,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _deletedUserCard(
      String deletedDocId,
      Map<String, dynamic> data, {
        required bool isDark,
      }) {
    final name = _text(data['deletedUserName'], fallback: 'No Name');
    final email = _text(data['deletedUserEmail'], fallback: 'No Email');
    final campus = _text(data['deletedUserCampus'], fallback: 'No campus');
    final course = _text(data['deletedUserCourse'], fallback: 'No course');
    final skills = _skillsText(data['deletedUserSkills']);
    final deletedBy = _text(data['deletedByEmail'], fallback: 'Unknown Admin');
    final deletedAt = _formatDate(data['deletedAt']);

    final isRestored = data['isRestored'] == true;
    final restoredBy = _text(data['restoredByEmail']);
    final restoredAt = _formatDate(data['restoredAt']);

    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isRestored ? green : red,
            child: Icon(
              isRestored ? Icons.restore_outlined : Icons.delete_outline,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text('Campus: $campus',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Course: $course',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Skills: $skills',
                    style: TextStyle(fontSize: 12, color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'Deleted by: $deletedBy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Deleted at: $deletedAt',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                if (isRestored) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restored by: $restoredBy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Restored at: $restoredAt',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      text: isRestored ? 'Restored' : 'Deleted User',
                      color: isRestored ? green : red,
                      isDark: isDark,
                    ),
                    if (!isRestored)
                      ElevatedButton.icon(
                        onPressed: () {
                          _confirmRestoreUser(
                            deletedDocId: deletedDocId,
                            data: data,
                          );
                        },
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Restore User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deletedPostCard(
      String deletedDocId,
      Map<String, dynamic> data, {
        required bool isDark,
      }) {
    final originalPostData = _originalData(data);

    final title = _text(
      data['title'] ??
          data['postTitle'] ??
          originalPostData['title'] ??
          originalPostData['postTitle'] ??
          originalPostData['skillTitle'],
      fallback: 'No title',
    );

    final description = _text(
      data['description'] ??
          originalPostData['description'] ??
          originalPostData['content'] ??
          originalPostData['details'],
      fallback: 'No description',
    );

    final postedBy = _text(
      data['postedBy'] ??
          data['ownerEmail'] ??
          originalPostData['userEmail'] ??
          originalPostData['email'] ??
          originalPostData['postedBy'],
      fallback: 'Unknown user',
    );

    final campus = _text(
      data['campus'] ??
          data['school'] ??
          originalPostData['campus'] ??
          originalPostData['school'],
      fallback: 'No campus',
    );

    final course = _text(
      data['course'] ??
          originalPostData['course'] ??
          originalPostData['studentCourse'] ??
          originalPostData['programme'] ??
          originalPostData['program'],
      fallback: 'No course',
    );

    final skills = _skillsText(
      data['skills'] ??
          originalPostData['skills'] ??
          originalPostData['skill'] ??
          originalPostData['skillNeeded'] ??
          originalPostData['skillTitle'],
    );

    final deletedBy = _text(data['deletedByEmail'], fallback: 'Unknown Admin');
    final deletedAt = _formatDate(data['deletedAt']);
    final isRestored = data['isRestored'] == true;
    final restoredBy = _text(data['restoredByEmail']);
    final restoredAt = _formatDate(data['restoredAt']);

    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isRestored ? green : red,
            child: Icon(
              isRestored ? Icons.restore_outlined : Icons.article_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text('Posted by: $postedBy',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Campus: $campus',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Course: $course',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Skills: $skills',
                    style: TextStyle(fontSize: 12, color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'Deleted by: $deletedBy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Deleted at: $deletedAt',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                if (isRestored) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restored by: $restoredBy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Restored at: $restoredAt',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      text: isRestored ? 'Restored' : 'Deleted Post',
                      color: isRestored ? green : red,
                      isDark: isDark,
                    ),
                    if (!isRestored)
                      ElevatedButton.icon(
                        onPressed: () {
                          _confirmRestorePost(
                            deletedDocId: deletedDocId,
                            data: data,
                          );
                        },
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Restore Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannedPostCard(
      String postId,
      Map<String, dynamic> data, {
        required bool isDark,
      }) {
    final title = _text(data['title'], fallback: 'No title');
    final description = _text(data['description'], fallback: 'No description');
    final postedBy =
    _text(data['postedBy'] ?? data['userEmail'], fallback: 'Unknown user');
    final campus = _text(data['campus'] ?? data['school'], fallback: 'No campus');
    final course = _text(data['course'], fallback: 'No course');
    final skills = _skillsText(data['skills'] ?? data['skillNeeded']);
    final bannedBy = _text(data['bannedByEmail'], fallback: 'Unknown Admin');
    final bannedAt = _formatDate(data['bannedAt']);
    final reason = _text(data['banReason'], fallback: 'No reason');

    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: orange,
            child: const Icon(
              Icons.block,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text('Posted by: $postedBy',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Campus: $campus',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Course: $course',
                    style: TextStyle(fontSize: 12, color: textColor)),
                Text('Skills: $skills',
                    style: TextStyle(fontSize: 12, color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'Banned by: $bannedBy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Banned at: $bannedAt',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                Text(
                  'Reason: $reason',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      text: 'Banned Post',
                      color: orange,
                      isDark: isDark,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _confirmUnbanPost(postId: postId, data: data);
                      },
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('Unban Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deletedUsersSection({required bool isDark}) {
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return _sectionBox(
      isDark: isDark,
      title: 'Deleted Users List',
      subtitle: 'Deleted user accounts archive',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deleted_users_history')
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _matchesUserSearch(data);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No deleted users found.',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _deletedUserCard(doc.id, data, isDark: isDark);
            },
          );
        },
      ),
    );
  }

  Widget _deletedPostsSection({required bool isDark}) {
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return _sectionBox(
      isDark: isDark,
      title: 'Deleted Posts List',
      subtitle: 'Deleted community skill swap listings',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deleted_posts_history')
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _matchesDeletedPostSearch(data);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No deleted posts found.',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _deletedPostCard(doc.id, data, isDark: isDark);
            },
          );
        },
      ),
    );
  }

  Widget _bannedPostsSection({required bool isDark}) {
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return _sectionBox(
      isDark: isDark,
      title: 'Banned Posts List',
      subtitle: 'Posts banned by admin or superadmin',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('status', isEqualTo: 'banned')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _matchesBannedPostSearch(data);
          }).toList();

          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['bannedAt'];
            final bTime = bData['bannedAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          if (filteredDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No banned posts found.',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _bannedPostCard(doc.id, data, isDark: isDark);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? darkBg : bg;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Audit Track Dashboard'),
        backgroundColor: isDark ? darkBg : navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchBox(isDark: isDark),
            const SizedBox(height: 20),
            _deletedUsersSection(isDark: isDark),
            const SizedBox(height: 24),
            _deletedPostsSection(isDark: isDark),
            const SizedBox(height: 24),
            _bannedPostsSection(isDark: isDark),
          ],
        ),
      ),
    );
  }
}