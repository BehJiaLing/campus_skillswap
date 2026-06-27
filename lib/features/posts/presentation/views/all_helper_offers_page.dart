import 'package:flutter/material.dart';
import '../../../../core/widgets/blocking_loading_overlay.dart';

import '../../models/ai_match.dart';
import '../../models/request_interactions.dart';
import '../../models/request_post.dart';
import '../view_models/request_post_detail_view_model.dart';

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

  static const navy = Color(0xFF1A1F5E);

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
            backgroundColor: const Color(0xFFF7F8FC),
            appBar: AppBar(
              title: Text('All Helper Offers (${offers.length})'),
              backgroundColor: const Color(0xFFF7F8FC),
              foregroundColor: const Color(0xFF1F223D),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                if (offers.length >= 2) ...[
                  FilledButton.icon(
                    onPressed: viewModel.busy
                        ? null
                        : () async {
                            final ok = await viewModel.rankHelperOffers(
                              post,
                              offers,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'AI ranking is ready.'
                                      : viewModel.errorMessage ??
                                            'Unable to rank offers.',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.leaderboard_rounded),
                    label: const Text('AI Rank Helper Offers'),
                  ),
                  const SizedBox(height: 18),
                ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFFC857) : const Color(0xFFE7EAF3),
          width: rank == 1 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rank == 1)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Container(
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
                      style: const TextStyle(color: Colors.grey),
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
                color: const Color(0xFFF2F5FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(ranking.reason, style: const TextStyle(height: 1.4)),
            ),
          ],
          if (post.status == RequestPostStatus.open) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
    );
  }

  Color _matchColor(int percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 65) return Colors.orange;
    return Colors.redAccent;
  }
}
