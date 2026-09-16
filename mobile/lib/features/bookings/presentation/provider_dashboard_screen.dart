import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/presentation/provider_profile_controller.dart';
import '../../providers/presentation/verification_badge.dart';
import '../../providers/domain/verification_status.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'request_card.dart';

/// A provider's "Jobs" tab (D1) - a dark-green hero card, a live stat row,
/// and the same incoming-requests list IncomingRequestsScreen shows in
/// full, capped to a handful here with a "History" link through to that
/// screen for the rest.
class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(providerProfileControllerProvider);
    final requestsState = ref.watch(incomingRequestsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final profile = profileState.valueOrNull;
    final bookings = requestsState.valueOrNull ?? const [];
    final newRequests = bookings.where((b) => b.status == BookingStatus.requested).length;
    final inProgress = bookings.where((b) => b.status == BookingStatus.inProgress).length;
    final completed = bookings
        .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.reviewed)
        .length;
    final rating = profile?.averageRating;

    return RefreshIndicator(
      onRefresh: () => Future.wait([
        ref.refresh(providerProfileControllerProvider.future),
        ref.refresh(incomingRequestsControllerProvider.future),
      ]),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(
              businessName: profile?.businessName,
              location: profile?.location,
              isApproved: profile?.verificationStatus == VerificationStatus.approved,
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text('Today\'s pulse', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.1,
              children: [
                _StatTile(
                  value: '$newRequests',
                  label: newRequests == 1 ? 'New request' : 'New requests',
                  icon: Icons.inbox_outlined,
                  color: colorScheme.secondary,
                ),
                _StatTile(
                  value: '$inProgress',
                  label: 'In progress',
                  icon: Icons.bolt_outlined,
                  color: colorScheme.primary,
                ),
                _StatTile(
                  value: '$completed',
                  label: 'Completed',
                  icon: Icons.check_circle_outline,
                  color: colorScheme.tertiary,
                ),
                _StatTile(
                  value: rating == null ? '-' : rating.toStringAsFixed(1),
                  label: profile == null || profile.reviewCount == 0 ? 'Rating' : 'Rating (${profile.reviewCount})',
                  icon: Icons.star_outline,
                  color: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Completed jobs & earnings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/earnings'),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: [
                Expanded(child: Text('Incoming requests', style: textTheme.titleLarge)),
                InkWell(
                  onTap: () => context.push('/incoming-requests'),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                    child: Text(
                      'History',
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            requestsState.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (error, _) => Text(
                'Could not load your requests.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Text(
                    'No requests yet - they\'ll show up here once a customer books one of your services.',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  );
                }
                const maxShown = 5;
                return Column(
                  children: [
                    for (final booking in bookings.take(maxShown)) ...[
                      RequestCard(booking: booking, onTap: () => context.push('/request-detail', extra: booking)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.businessName, required this.location, required this.isApproved});

  final String? businessName;
  final String? location;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location ?? 'Provider dashboard',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessName ?? 'Set up your business profile',
                    style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            if (isApproved)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  child: Text(
                    'ONLINE',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              VerificationBadge(status: VerificationStatus.pending),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.icon, required this.color});

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: textTheme.titleLarge),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
