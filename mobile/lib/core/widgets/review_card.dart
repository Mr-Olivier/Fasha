import 'package:flutter/material.dart';

import '../../features/reviews/domain/review.dart';
import '../../features/reviews/domain/review_tag.dart';
import '../theme/app_theme.dart';
import 'star_rating.dart';

/// A single review - reviewer name, stars, comment, and any "what stood
/// out" tags. Shared by ProviderDetailScreen's preview and the All
/// Reviews screen so both render reviews identically.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(review.customerName, style: textTheme.titleMedium)),
                Text(
                  '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            StarRating(rating: review.rating.toDouble(), size: 14),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(review.comment!, style: textTheme.bodyMedium),
            ],
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in review.tags)
                    Chip(
                      label: Text(tag.label, style: textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
