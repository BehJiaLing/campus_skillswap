import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> showUserProfileDialog(
  BuildContext context, {
  required String userId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close profile',
    barrierColor: Colors.black54,
    pageBuilder: (context, _, _) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: _PublicProfileCard(userId: userId),
        ),
      ),
    ),
  );
}

Future<void> showUserReviewsDialog(
  BuildContext context, {
  required String userId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close reviews',
    barrierColor: Colors.black54,
    pageBuilder: (context, _, _) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: _PublicProfileCard(userId: userId, reviewsOnly: true),
        ),
      ),
    ),
  );
}

class _PublicProfileCard extends StatelessWidget {
  const _PublicProfileCard({required this.userId, this.reviewsOnly = false});

  final String userId;
  final bool reviewsOnly;

  Future<List<_ReviewItem>> _reviews() async {
    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .where('matchedUserId', isEqualTo: userId)
        .get();
    final items = <_ReviewItem>[];
    for (final post in posts.docs) {
      final ratings = await post.reference.collection('ratings').get();
      for (final rating in ratings.docs) {
        final data = rating.data();
        if (data['toUserId'] != userId) continue;
        items.add(
          _ReviewItem(
            postId: post.id,
            title: post.data()['title']?.toString() ?? 'Skill exchange',
            date: (data['createdAt'] as Timestamp?)?.toDate(),
            stars: (data['stars'] as num?)?.toInt() ?? 0,
            review: data['review']?.toString() ?? '',
          ),
        );
      }
    }
    items.sort(
      (a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)),
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: MediaQuery.sizeOf(context).width * .9,
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: MediaQuery.sizeOf(context).height * .84,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final name = (data['name'] ?? data['fullName'] ?? 'Student')
              .toString();
          final photo = (data['photoUrl'] ?? data['profileImageUrl'] ?? '')
              .toString();
          final skills = data['skills'] is Iterable
              ? (data['skills'] as Iterable)
                    .map((item) => item.toString())
                    .toList()
              : <String>[];
          final rating = (data['averageRating'] as num?)?.toDouble() ?? 0;
          final points = (data['rewardPoints'] as num?)?.toInt() ?? 0;
          return Column(
            children: [
              if (reviewsOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Previous Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              if (!reviewsOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 31,
                        backgroundImage: photo.isEmpty
                            ? null
                            : NetworkImage(photo),
                        child: photo.isEmpty
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text((data['course'] ?? 'Student').toString()),
                            Text(
                              (data['campus'] ?? data['school'] ?? '')
                                      .toString()
                                      .trim()
                                      .isEmpty
                                  ? 'Campus: TBC'
                                  : 'Campus: ${data['campus'] ?? data['school']}',
                            ),
                            Text(
                              '★ ${rating.toStringAsFixed(1)}  •  $points points',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              if (!reviewsOnly && skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: skills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                ),
              const Divider(height: 24),
              if (!reviewsOnly)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Previous Reviews',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<_ReviewItem>>(
                  future: _reviews(),
                  builder: (context, reviews) {
                    if (reviews.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Unable to load previous reviews.'),
                        ),
                      );
                    }
                    if (!reviews.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (reviews.data!.isEmpty) {
                      return const Center(
                        child: Text('No previous ratings or comments yet.'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                      itemCount: reviews.data!.length,
                      itemBuilder: (context, index) {
                        final item = reviews.data![index];
                        return Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/post-detail',
                                arguments: item.postId,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    item.date == null
                                        ? '-'
                                        : '${item.date!.day}/${item.date!.month}/${item.date!.year}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${'★' * item.stars}${'☆' * (5 - item.stars)}',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    item.review.isEmpty
                                        ? 'No written comment.'
                                        : item.review,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({
    required this.postId,
    required this.title,
    required this.date,
    required this.stars,
    required this.review,
  });
  final String postId;
  final String title;
  final DateTime? date;
  final int stars;
  final String review;
}
