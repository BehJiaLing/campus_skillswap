import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _navy = Color(0xFF102A72);
const _green = Color(0xFF12A875);

Future<void> showUserProfileDialog(
  BuildContext context, {
  required String userId,
}) => _showProfileSurface(context, userId: userId);

Future<void> showUserReviewsDialog(
  BuildContext context, {
  required String userId,
}) => _showProfileSurface(context, userId: userId, reviewsOnly: true);

Future<void> _showProfileSurface(
  BuildContext context, {
  required String userId,
  bool reviewsOnly = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: reviewsOnly ? 'Close reviews' : 'Close profile',
    barrierColor: Colors.black.withValues(alpha: .64),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: _PublicProfileCard(userId: userId, reviewsOnly: reviewsOnly),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: .96, end: 1).animate(animation),
        child: child,
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
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: size.width * .91,
      constraints: BoxConstraints(maxWidth: 540, maxHeight: size.height * .86),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _messageState(
              context,
              icon: Icons.error_outline_rounded,
              message: 'Unable to load this profile.',
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator(color: _green)),
            );
          }

          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final name = (data['name'] ?? data['fullName'] ?? 'Student')
              .toString();
          final photo = (data['photoUrl'] ?? data['profileImageUrl'] ?? '')
              .toString();
          final course = (data['course'] ?? 'Student').toString();
          final campus = (data['campus'] ?? data['school'] ?? '')
              .toString()
              .trim();
          final skills = data['skills'] is Iterable
              ? (data['skills'] as Iterable)
                    .map((item) => item.toString())
                    .toList()
              : <String>[];
          final rating = (data['averageRating'] as num?)?.toDouble() ?? 0;
          final points = (data['rewardPoints'] as num?)?.toInt() ?? 0;

          return Column(
            children: [
              _profileHeader(
                context,
                name: name,
                photo: photo,
                course: course,
                campus: campus,
                rating: rating,
                points: points,
              ),
              if (!reviewsOnly && skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: skills
                          .map(
                            (skill) => Chip(
                              label: Text(skill),
                              side: BorderSide.none,
                              backgroundColor: _green.withValues(alpha: .10),
                              labelStyle: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              if (!reviewsOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'Previous Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 14),
              Expanded(child: _reviewList(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _profileHeader(
    BuildContext context, {
    required String name,
    required String photo,
    required String course,
    required String campus,
    required double rating,
    required int points,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 10, 19),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF102A72), Color(0xFF17469A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!reviewsOnly)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFE8EEFF),
                backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                child: photo.isEmpty
                    ? const Icon(Icons.person_rounded, size: 36, color: _navy)
                    : null,
              ),
            ),
          if (!reviewsOnly) const SizedBox(width: 14),
          Expanded(
            child: reviewsOnly
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      'Previous Reviews',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                        ),
                      ),
                      Text(
                        campus.isEmpty ? 'Campus: TBC' : 'Campus: $campus',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _headerPill(
                            Icons.star_rounded,
                            rating.toStringAsFixed(1),
                          ),
                          _headerPill(
                            Icons.workspace_premium_rounded,
                            '$points points',
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          IconButton.filledTonal(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _headerPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: icon == Icons.star_rounded ? Colors.amber : Colors.white,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _reviewList(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<_ReviewItem>>(
      future: _reviews(),
      builder: (context, reviews) {
        if (reviews.hasError) {
          return _messageState(
            context,
            icon: Icons.cloud_off_rounded,
            message: 'Unable to load previous reviews.',
          );
        }
        if (!reviews.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        if (reviews.data!.isEmpty) {
          return _messageState(
            context,
            icon: Icons.rate_review_outlined,
            message: 'No previous ratings or comments yet.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          itemCount: reviews.data!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = reviews.data![index];
            return Material(
              color: colors.surfaceContainerHighest.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/post-detail',
                    arguments: item.postId,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: .55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.date == null
                            ? 'Date unavailable'
                            : '${item.date!.day}/${item.date!.month}/${item.date!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (star) => Icon(
                            star < item.stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.review.isEmpty
                            ? 'No written comment.'
                            : item.review,
                        style: const TextStyle(height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _messageState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _green.withValues(alpha: .10),
            child: Icon(icon, color: _green, size: 29),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
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
