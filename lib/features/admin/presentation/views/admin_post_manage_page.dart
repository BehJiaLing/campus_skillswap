import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_drawer.dart';

class AdminPostManagementPage extends StatefulWidget {
  const AdminPostManagementPage({super.key});

  @override
  State<AdminPostManagementPage> createState() =>
      _AdminPostManagementPageState();
}

class _AdminPostManagementPageState extends State<AdminPostManagementPage> {
  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color red = const Color(0xFFFF4D4D);
  final Color orange = const Color(0xFFFF9800);
  final Color textMid = const Color(0xFF555577);
  final Color border = const Color(0xFFE0E0F0);

  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkBorder = const Color(0xFF374151);
  final Color darkField = const Color(0xFF111827);

  final TextEditingController searchController = TextEditingController();

  String sortOrder = 'latest';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> deletePost(BuildContext context, _PostViewData post) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? darkCard : Colors.white,
          title: Text(
            'Delete Post',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this post? The deleted post record will be saved in Audit Track.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final admin = FirebaseAuth.instance.currentUser;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.postId);

      final postSnapshot = await postRef.get();
      final originalData = postSnapshot.data() ?? {};

      final deletedRef = FirebaseFirestore.instance
          .collection('deleted_posts_history')
          .doc(post.postId);

      final batch = FirebaseFirestore.instance.batch();

      batch.set(deletedRef, {
        'postId': post.postId,
        'title': post.title,
        'postTitle': post.title,
        'description': post.description,
        'postedBy': post.postedBy,
        'ownerUid': post.ownerUid,
        'ownerEmail': post.ownerEmail,
        'course': post.course,
        'skills': post.skills,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedByUid': admin?.uid,
        'deletedByEmail': admin?.email,
        'restored': false,
        'isRestored': false,
        'originalData': originalData,
      });

      batch.update(postRef, {
        'isDeleted': true,
        'previousStatus': originalData['status'] ?? 'open',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedByUid': admin?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (post.ownerUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientId': post.ownerUid,
          'senderId': admin?.uid ?? '',
          'senderName': 'Campus SkillSwap Admin',
          'type': 'post_deleted',
          'postId': post.postId,
          'postTitle': post.title,
          'message': 'Your post was removed and moved to the recovery audit.',
          'status': 'rejected',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> banPost(BuildContext context, _PostViewData post) async {
    if (post.isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This post is already banned')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? darkCard : Colors.white,
          title: Text(
            'Ban Post',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to ban this post? The post will not be removed, but it will be marked as banned.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ban Post'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final admin = FirebaseAuth.instance.currentUser;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.postId);

      await postRef.set({
        'isBanned': true,
        'banned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedByUid': admin?.uid,
        'bannedByEmail': admin?.email,
        'banReason': 'Banned from Post Management',
      }, SetOptions(merge: true));

      if (post.ownerUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientId': post.ownerUid,
          'senderId': admin?.uid ?? '',
          'senderName': 'Campus SkillSwap Admin',
          'type': 'post_banned',
          'postId': post.postId,
          'postTitle': post.title,
          'message': 'Your post was banned by an administrator.',
          'status': 'rejected',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('banned_posts_history')
          .doc(post.postId)
          .set({
            'postId': post.postId,
            'title': post.title,
            'postTitle': post.title,
            'description': post.description,
            'postedBy': post.postedBy,
            'ownerUid': post.ownerUid,
            'ownerEmail': post.ownerEmail,
            'course': post.course,
            'skills': post.skills,
            'bannedAt': FieldValue.serverTimestamp(),
            'bannedByUid': admin?.uid,
            'bannedByEmail': admin?.email,
            'status': 'moderation_banned',
          }, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post banned successfully')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ban post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime getDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime(2000);
  }

  String formatDate(dynamic value) {
    if (value == null) return 'No date';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return value.toString();
  }

  String getText(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      if (data[key] != null && data[key].toString().trim().isNotEmpty) {
        return data[key].toString();
      }
    }

    return fallback;
  }

  _LinkedUserData findUserData({
    required Map<String, dynamic> postData,
    required Map<String, _LinkedUserData> usersByUid,
    required Map<String, _LinkedUserData> usersByEmail,
  }) {
    final uidKeys = [
      'uid',
      'userId',
      'createdById',
      'postedByUid',
      'ownerId',
      'authorId',
    ];

    for (final key in uidKeys) {
      final value = postData[key]?.toString();

      if (value != null && usersByUid.containsKey(value)) {
        return usersByUid[value]!;
      }
    }

    final emailKeys = [
      'userEmail',
      'email',
      'postedBy',
      'createdBy',
      'authorEmail',
    ];

    for (final key in emailKeys) {
      final value = postData[key]?.toString().toLowerCase();

      if (value != null && usersByEmail.containsKey(value)) {
        return usersByEmail[value]!;
      }
    }

    return _LinkedUserData(uid: '', data: {});
  }

  String getCourse(
    Map<String, dynamic> postData,
    Map<String, dynamic> userData,
  ) {
    final postCourse = getText(postData, [
      'course',
      'studentCourse',
      'programme',
      'program',
    ], '');

    if (postCourse.isNotEmpty) return postCourse.trim();

    final userCourse = getText(userData, [
      'course',
      'studentCourse',
      'programme',
      'program',
    ], '');

    if (userCourse.isNotEmpty) return userCourse.trim();

    return 'No course';
  }

  List<String> getSkills(
    Map<String, dynamic> postData,
    Map<String, dynamic> userData,
  ) {
    final List<String> skills = [];

    void addSkill(dynamic value) {
      if (value == null) return;

      if (value is List) {
        for (final item in value) {
          final skill = item.toString().trim();

          if (skill.isNotEmpty &&
              skill.toLowerCase() != 'no category' &&
              !skills.contains(skill)) {
            skills.add(skill);
          }
        }
      } else {
        final splitSkills = value.toString().split(',');

        for (final item in splitSkills) {
          final skill = item.trim();

          if (skill.isNotEmpty &&
              skill.toLowerCase() != 'no category' &&
              !skills.contains(skill)) {
            skills.add(skill);
          }
        }
      }
    }

    addSkill(userData['skills']);
    addSkill(userData['skill']);
    addSkill(userData['studentSkills']);

    addSkill(postData['skills']);
    addSkill(postData['skill']);
    addSkill(postData['skillTitle']);
    addSkill(postData['skillNeeded']);

    if (skills.isEmpty) {
      return ['No skills'];
    }

    return skills;
  }

  bool matchesSearch(_PostViewData item) {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    final searchableText = [
      item.title,
      item.description,
      item.postedBy,
      item.course,
      item.skills.join(', '),
      item.isBanned ? 'banned' : 'active',
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? darkBg : bg;
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);

    return Scaffold(
      backgroundColor: pageBg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: isDark ? darkBg : navy,
        foregroundColor: Colors.white,
        title: const Text('Post Management'),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading posts',
                style: TextStyle(color: textColor),
              ),
            );
          }

          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = postSnapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = userSnapshot.data?.docs ?? [];

              final Map<String, _LinkedUserData> usersByUid = {};
              final Map<String, _LinkedUserData> usersByEmail = {};

              for (final userDoc in users) {
                final userData = userDoc.data();

                final linkedUser = _LinkedUserData(
                  uid: userDoc.id,
                  data: userData,
                );

                usersByUid[userDoc.id] = linkedUser;

                final email = userData['email']?.toString().toLowerCase();

                if (email != null && email.isNotEmpty) {
                  usersByEmail[email] = linkedUser;
                }
              }

              final List<_PostViewData> allPosts = posts
                  .where((post) => post.data()['isDeleted'] != true)
                  .map((post) {
                    final data = post.data();

                    final linkedUser = findUserData(
                      postData: data,
                      usersByUid: usersByUid,
                      usersByEmail: usersByEmail,
                    );

                    final userData = linkedUser.data;

                    final title = getText(data, [
                      'title',
                      'postTitle',
                      'skillTitle',
                      'subject',
                    ], 'No title');

                    final description = getText(data, [
                      'description',
                      'content',
                      'details',
                      'message',
                    ], 'No description');

                    final postEmail = getText(data, [
                      'userEmail',
                      'email',
                      'postedBy',
                      'createdBy',
                      'authorEmail',
                    ], '');

                    final userEmail = getText(userData, ['email'], '');
                    final userName = getText(userData, [
                      'name',
                      'fullName',
                    ], '');

                    final postedBy = postEmail.isNotEmpty
                        ? postEmail
                        : userEmail.isNotEmpty
                        ? userEmail
                        : userName.isNotEmpty
                        ? userName
                        : 'Unknown user';

                    final ownerEmail = userEmail.isNotEmpty
                        ? userEmail
                        : postEmail;

                    final createdAt = formatDate(data['createdAt']);
                    final createdDate = getDateTime(data['createdAt']);

                    final course = getCourse(data, userData);
                    final skills = getSkills(data, userData);

                    final isBanned =
                        data['isBanned'] == true ||
                        data['banned'] == true ||
                        data['status'] == 'banned';

                    return _PostViewData(
                      postId: post.id,
                      title: title,
                      description: description,
                      postedBy: postedBy,
                      createdAt: createdAt,
                      createdDate: createdDate,
                      course: course,
                      skills: skills,
                      ownerUid: linkedUser.uid,
                      ownerEmail: ownerEmail,
                      isBanned: isBanned,
                    );
                  })
                  .toList();

              final filteredPosts = allPosts.where((post) {
                return matchesSearch(post);
              }).toList();

              filteredPosts.sort((a, b) {
                if (sortOrder == 'latest') {
                  return b.createdDate.compareTo(a.createdDate);
                } else {
                  return a.createdDate.compareTo(b.createdDate);
                }
              });

              return Column(
                children: [
                  _searchSection(
                    totalPosts: allPosts.length,
                    filteredPosts: filteredPosts.length,
                    isDark: isDark,
                  ),
                  Expanded(
                    child: filteredPosts.isEmpty
                        ? Center(
                            child: Text(
                              'No posts found',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : navy,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index];
                              return _postCard(context, post, isDark: isDark);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _searchSection({
    required int totalPosts,
    required int filteredPosts,
    required bool isDark,
  }) {
    final cardColor = isDark ? darkCard : Colors.white;
    final fieldColor = isDark ? darkField : bg;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);
    final subTextColor = isDark ? Colors.white60 : textMid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: cardColor,
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: TextStyle(color: textColor),
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search post title, email, course or skill',
              hintStyle: TextStyle(color: subTextColor),
              prefixIcon: Icon(Icons.search, color: subTextColor),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: subTextColor),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: fieldColor,
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
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: sortOrder,
            dropdownColor: isDark ? darkCard : Colors.white,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Sort by',
              labelStyle: TextStyle(color: subTextColor),
              filled: true,
              fillColor: fieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: lineColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: lineColor),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'latest', child: Text('Latest first')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                sortOrder = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $filteredPosts of $totalPosts posts',
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    sortOrder = 'latest';
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _postCard(
    BuildContext context,
    _PostViewData post, {
    required bool isDark,
  }) {
    final cardColor = isDark ? darkCard : Colors.white;
    final innerColor = isDark ? darkField : bg;
    final lineColor = isDark ? darkBorder : border;
    final subTextColor = isDark ? Colors.white60 : textMid;
    final titleColor = post.isBanned
        ? Colors.grey
        : isDark
        ? Colors.white
        : navy;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: lineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: post.isBanned
                      ? Colors.grey
                      : isDark
                      ? const Color(0xFF312E81)
                      : navy,
                  child: const Icon(
                    Icons.article_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (post.isBanned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2F1518)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Banned Post',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.description,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: innerColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: lineColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoText('Posted by', post.postedBy, isDark: isDark),
                  _infoText('Course', post.course, isDark: isDark),
                  _infoText('Skills', post.skills.join(', '), isDark: isDark),
                  _infoText('Date', post.createdAt, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: post.isBanned
                        ? null
                        : () {
                            banPost(context, post);
                          },
                    icon: Icon(
                      post.isBanned ? Icons.block : Icons.block_outlined,
                      size: 18,
                    ),
                    label: Text(post.isBanned ? 'Banned' : 'Ban Post'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      disabledForegroundColor: Colors.grey,
                      side: BorderSide(
                        color: post.isBanned ? Colors.grey : orange,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      deletePost(context, post);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(String label, String value, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : const Color(0xFF1F223D),
        ),
      ),
    );
  }
}

class _LinkedUserData {
  final String uid;
  final Map<String, dynamic> data;

  _LinkedUserData({required this.uid, required this.data});
}

class _PostViewData {
  final String postId;
  final String title;
  final String description;
  final String postedBy;
  final String createdAt;
  final DateTime createdDate;
  final String course;
  final List<String> skills;
  final String ownerUid;
  final String ownerEmail;
  final bool isBanned;

  _PostViewData({
    required this.postId,
    required this.title,
    required this.description,
    required this.postedBy,
    required this.createdAt,
    required this.createdDate,
    required this.course,
    required this.skills,
    required this.ownerUid,
    required this.ownerEmail,
    required this.isBanned,
  });
}
