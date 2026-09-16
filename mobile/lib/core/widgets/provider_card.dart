import 'package:flutter/material.dart';

import '../../features/providers/domain/provider_profile.dart';
import '../../features/providers/domain/verification_status.dart';
import '../network/api_client.dart';
import '../theme/app_theme.dart';
import 'star_rating.dart';

/// A provider row/card - shared by the Explore tab's search results and
/// Home's "Top rated near you" section, so both stay visually identical
/// instead of drifting apart (previously ProviderListScreen built this
/// inline, with no reusable widget for Home to share).
class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider, required this.onTap});

  final ProviderProfile provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                // StaticResourceConfig serves this at the backend's plain
                // host, not under "/api" - see ApiClient.mediaBaseUrl's doc
                // comment. Only the initial shows while a real photo is
                // still loading (or if the provider never uploaded one) -
                // CircleAvatar's own child is masked out once
                // backgroundImage successfully paints over it.
                backgroundImage: provider.profileImageUrl != null
                    ? NetworkImage('${ApiClient.mediaBaseUrl}${provider.profileImageUrl}')
                    : null,
                child: provider.profileImageUrl == null
                    ? Text(
                        provider.businessName.isNotEmpty ? provider.businessName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.businessName,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.verificationStatus == VerificationStatus.approved) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 16, color: colorScheme.tertiary),
                        ],
                        const Spacer(),
                        if (provider.isFavorited) Icon(Icons.favorite, size: 16, color: colorScheme.error),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        provider.location ?? 'Location not specified',
                        if (provider.yearsExperience != null)
                          '${provider.yearsExperience} yr${provider.yearsExperience == 1 ? '' : 's'} exp.',
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 4),
                    if (provider.averageRating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StarRating(rating: provider.averageRating!, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.averageRating!.toStringAsFixed(1)} (${provider.reviewCount})',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      )
                    else
                      Text('No reviews yet', style: textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
