import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/review_card.dart';
import '../../providers/presentation/provider_profile_controller.dart';
import 'review_controller.dart';

/// A provider's own "Reviews" tab - what customers have said about them.
/// Reuses providerReviewsProvider as-is (the same public
/// GET /api/providers/{id}/reviews ProviderDetailScreen already calls),
/// just fed the logged-in provider's own id instead of one from a route.
class ProviderReviewsScreen extends ConsumerWidget {
  const ProviderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(providerProfileControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final providerId = profileState.valueOrNull?.id;

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Fasha Pro', subtitle: 'Reviews'),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : providerId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Text(
                      'Set up your provider profile first - reviews show up here once customers can find and book you.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                )
              : _ReviewsList(providerId: providerId),
    );
  }
}

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsState = ref.watch(providerReviewsProvider(providerId));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return reviewsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Could not load your reviews.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(
                'No reviews yet - they\'ll show up here once a customer reviews a completed job.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(providerReviewsProvider(providerId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => ReviewCard(review: reviews[index]),
          ),
        );
      },
    );
  }
}
