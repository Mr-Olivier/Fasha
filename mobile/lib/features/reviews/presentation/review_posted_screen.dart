import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../bookings/domain/booking.dart';

/// What WriteReviewScreen hands to this screen via `extra`.
typedef ReviewPostedArgs = ({Booking booking, int rating});

/// Confirmation shown right after a review is submitted (mockup screen
/// C7) - replaces the previous toast-then-pop behaviour. "Book again"
/// goes to the provider's profile (not straight back into a pre-filled
/// request form) since a Booking doesn't carry every ServiceListing field
/// (duration, visibility, category) needed to safely reconstruct one -
/// the provider's services may also have changed since this booking was
/// made, so re-picking is more honest than silently reusing stale data.
class ReviewPostedScreen extends StatelessWidget {
  const ReviewPostedScreen({super.key, required this.args});

  final ReviewPostedArgs args;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final booking = args.booking;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.star, size: 64, color: colorScheme.secondary),
              const SizedBox(height: AppSpacing.gutter),
              Text('Thank you', style: textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your review is live on ${booking.providerBusinessName}\'s profile. Ratings like yours are what keep FASHA trustworthy.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _Row(label: 'Service', value: booking.serviceName),
                      const Divider(height: AppSpacing.gutter),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your rating', style: textTheme.bodyMedium),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < args.rating ? Icons.star : Icons.star_border,
                                size: 18,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/providers/${booking.providerProfileId}'),
                child: Text('Book ${booking.providerBusinessName} again'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.go('/bookings'),
                child: const Text('Back to bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}
