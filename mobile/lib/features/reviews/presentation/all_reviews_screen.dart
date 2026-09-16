import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/review_card.dart';
import '../domain/review.dart';
import 'review_controller.dart';

enum _ReviewSort { newest, highestRated }

/// Every review for one provider (mockup screen B6) - reached from
/// ProviderDetailScreen's "See all" link. Shows the rating breakdown (how
/// many 5-star/4-star/... reviews) computed client-side from the same list
/// ProviderDetailScreen's preview already fetches (providerReviewsProvider
/// is cached per providerId, so this is the same data, not a second
/// network round trip in practice).
class AllReviewsScreen extends ConsumerStatefulWidget {
  const AllReviewsScreen({super.key, required this.providerId});

  final String providerId;

  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  _ReviewSort _sort = _ReviewSort.newest;

  List<Review> _sorted(List<Review> reviews) {
    final copy = [...reviews];
    switch (_sort) {
      case _ReviewSort.newest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _ReviewSort.highestRated:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(providerReviewsProvider(widget.providerId));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: reviewsState.valueOrNull != null
            ? Text('Reviews · ${reviewsState.value!.length}')
            : const Text('Reviews'),
      ),
      body: reviewsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load reviews.')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No reviews yet.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }

          final average = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          final countByStar = {for (var star = 5; star >= 1; star--) star: reviews.where((r) => r.rating == star).length};
          final sorted = _sorted(reviews);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(average.toStringAsFixed(1), style: textTheme.headlineMedium),
                      Icon(Icons.star, size: 16, color: colorScheme.secondary),
                      Text('${reviews.length} review${reviews.length == 1 ? '' : 's'}', style: textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      children: [
                        for (final star in countByStar.keys)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('$star', style: textTheme.bodySmall),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: countByStar[star]! / reviews.length,
                                      minHeight: 8,
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('Newest'),
                    selected: _sort == _ReviewSort.newest,
                    onSelected: (_) => setState(() => _sort = _ReviewSort.newest),
                  ),
                  ChoiceChip(
                    label: const Text('Highest rated'),
                    selected: _sort == _ReviewSort.highestRated,
                    onSelected: (_) => setState(() => _sort = _ReviewSort.highestRated),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final review in sorted) ...[
                ReviewCard(review: review),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}
