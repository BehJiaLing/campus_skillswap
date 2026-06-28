import 'package:flutter/material.dart';
import '../../../../core/widgets/blocking_loading_overlay.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';

import '../../models/ai_match.dart';
import '../../models/request_interactions.dart';
import '../../models/request_post.dart';
import '../view_models/request_post_detail_view_model.dart';
import '../../../profile/presentation/views/user_profile_dialog.dart';

class AllHelperOffersPage extends StatelessWidget {
  const AllHelperOffersPage({
    super.key,
    required this.post,
    required this.offers,
    required this.viewModel,
  });

  final RequestPost post;
  final List<HelpOffer> offers;
  final RequestPostDetailViewModel viewModel;

  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final rankedById = <String, AiMatch>{
          for (final item in viewModel.rankedOffers) item.userId: item,
        };
        final sorted = [...offers];
        if (rankedById.isNotEmpty) {
          sorted.sort(
            (a, b) => (rankedById[b.userId]?.matchPercentage ?? 0).compareTo(
              rankedById[a.userId]?.matchPercentage ?? 0,
            ),
          );
        }
        return BlockingLoadingOverlay(
          loading: viewModel.busy,
          message: 'AI is ranking helper offers...',
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF4F7FB),
            body: SafeArea(
              child: Column(
                children: [
                  SkillSwapPageHeader(
                    title: 'Helper Offers',
                    subtitle: '${offers.length} students offered to help.',
                    trailing: IconButton.filledTonal(
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                      children: [
                        if (offers.length >= 2) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  navy.withValues(alpha: .10),
                                  green.withValues(alpha: .10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: navy.withValues(alpha: .12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Need help choosing?',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AI compares every offer and explains the strongest matches.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: navy,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: viewModel.busy
                                        ? null
                                        : () async {
                                            final ok = await viewModel
                                                .rankHelperOffers(post, offers);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'AI ranking is ready.'
                                                      : viewModel
                                                                .errorMessage ??
                                                            'Unable to rank offers.',
                                                ),
                                                backgroundColor: ok
                                                    ? green
                                                    : Colors.red,
                                              ),
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.auto_awesome_rounded,
                                    ),
                                    label: const Text('AI Rank Helper Offers'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_alt_rounded,
                                color: green,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Text(
                                'All Offers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${offers.length}',
                              style: const TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(sorted.length, (index) {
                          final offer = sorted[index];
                          return _offerCard(
                            context,
                            offer,
                            rankedById[offer.userId],
                            rankedById.isEmpty ? null : index + 1,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _offerCard(
    BuildContext context,
    HelpOffer offer,
    AiMatch? ranking,
    int? rank,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => showUserProfileDialog(context, userId: offer.userId),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: rank == 1
                    ? const Color(0xFFFFC857)
                    : colors.outlineVariant.withValues(alpha: .65),
                width: rank == 1 ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: .06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rank == 1)
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
                    GestureDetector(
                      onTap: () =>
                          showUserProfileDialog(context, userId: offer.userId),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ranking == null
                              ? const Color(0xFFEAF2FF)
                              : _matchColor(
                                  ranking.matchPercentage,
                                ).withValues(alpha: .13),
                          border: ranking == null
                              ? null
                              : Border.all(
                                  color: _matchColor(ranking.matchPercentage),
                                  width: 2,
                                ),
                        ),
                        alignment: Alignment.center,
                        child: ranking == null
                            ? const Icon(Icons.person, color: navy, size: 31)
                            : Text(
                                '${ranking.matchPercentage}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _matchColor(ranking.matchPercentage),
                                ),
                              ),
                      ),
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
                            ),
                          ),
                          Text(
                            offer.course,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ranking != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: offer.skills
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            backgroundColor: const Color(0xFFEAF2FF),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: ranking.matchPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: _matchColor(ranking.matchPercentage),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      ranking.reason,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
                if (post.status == RequestPostStatus.open) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: viewModel.busy
                          ? null
                          : () async {
                              final ok = await viewModel.acceptCandidate(
                                post,
                                helperId: offer.userId,
                                helperName: offer.userName,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? '${offer.userName} was selected.'
                                        : viewModel.errorMessage ??
                                              'Unable to select helper.',
                                  ),
                                  backgroundColor: ok ? green : Colors.red,
                                ),
                              );
                              if (ok) Navigator.pop(context);
                            },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Choose This Helper'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _matchColor(int percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 65) return Colors.orange;
    return Colors.redAccent;
  }
}
