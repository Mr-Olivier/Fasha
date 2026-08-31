import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/star_rating.dart';
import '../../reviews/presentation/review_controller.dart';
import 'provider_browse_controller.dart';

/// Customer-facing public profile - business info plus every service they
/// offer. Tapping a service goes straight to requesting a booking for it.
class ProviderDetailScreen extends ConsumerWidget {
  const ProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(providerDetailProvider(providerId));
    final reviewsState = ref.watch(providerReviewsProvider(providerId));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Provider')),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load this provider.')),
        data: (detail) {
          final profile = detail.profile;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.businessName, style: textTheme.titleLarge),
                        if (profile.location != null) ...[
                          const SizedBox(height: 2),
                          Text(profile.location!, style: textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 4),
                        if (profile.averageRating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StarRating(rating: profile.averageRating!, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${profile.averageRating!.toStringAsFixed(1)} (${profile.reviewCount} review${profile.reviewCount == 1 ? '' : 's'})',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          )
                        else
                          Text('No reviews yet', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.description != null && profile.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.gutter),
                Text(profile.description!, style: textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.gutter),
              Text('Services', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (detail.services.isEmpty)
                Text(
                  'This provider hasn\'t listed any services yet.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                )
              else
                for (final service in detail.services) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(service.name),
                      subtitle: service.description != null ? Text(service.description!) : null,
                      trailing: Text(
                        'RWF ${service.price.toStringAsFixed(0)}',
                        style: textTheme.titleMedium,
                      ),
                      onTap: () => context.push('/request-booking', extra: service),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.gutter),
              Text('Reviews', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              reviewsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  'Could not load reviews.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return Text(
                      'No reviews yet.',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final review in reviews) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(review.customerName, style: textTheme.titleMedium)),
                                    StarRating(rating: review.rating.toDouble(), size: 14),
                                  ],
                                ),
                                if (review.comment != null && review.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(review.comment!, style: textTheme.bodyMedium),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
