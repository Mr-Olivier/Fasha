import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/pending_provider.dart';
import 'admin_provider_controller.dart';

/// Admin's "Review application" queue (E1/E2 in fasha-app-final-ui.html,
/// simplified into one list-with-actions screen instead of separate
/// overview + detail screens). Before this screen existed, the ONLY way to
/// approve a new provider was a developer running a direct database
/// UPDATE - this is what makes provider onboarding actually usable without
/// a developer in the loop.
class AdminProvidersScreen extends ConsumerStatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  ConsumerState<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends ConsumerState<AdminProvidersScreen> {
  // Tracks which card's Approve/Reject is in flight, so only THAT card shows
  // a spinner - decideProviderControllerProvider only holds one in-flight
  // decision at a time, not which provider it belongs to.
  String? _busyProviderId;

  Future<void> _decide(PendingProvider provider, bool approved) {
    _busyProviderId = provider.id;
    return ref.read(decideProviderControllerProvider.notifier).decide(providerId: provider.id, approved: approved);
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingProvidersProvider);
    // Watched (not just listened to) so this widget actually rebuilds when
    // it changes - see EditProfileScreen's identical isSubmitting pattern
    // for why that matters.
    final decideState = ref.watch(decideProviderControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(decideProviderControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        _busyProviderId = null;
        AppToast.apiError(context, error);
        return;
      }
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        _busyProviderId = null;
        AppToast.success(context, 'Decision saved.');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Provider approvals')),
      body: pendingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load pending providers.')),
        data: (providers) {
          if (providers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No pending applications. New provider sign-ups will show up here for review.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(pendingProvidersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final provider = providers[index];
                final isBusy = decideState.isLoading && _busyProviderId == provider.id;
                return _ProviderCard(
                  provider: provider,
                  isBusy: isBusy,
                  onApprove: isBusy ? null : () => _decide(provider, true),
                  onReject: isBusy ? null : () => _decide(provider, false),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.isBusy, required this.onApprove, required this.onReject});

  final PendingProvider provider;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

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
            Text(provider.businessName, style: textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              [provider.location, 'applied ${_formatDate(provider.appliedAt)}']
                  .where((part) => part != null && part.isNotEmpty)
                  .join(' · '),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Owner', style: textTheme.labelLarge),
            Text(provider.ownerName, style: textTheme.bodyMedium),
            Text(provider.ownerEmail, style: textTheme.bodySmall),
            if (provider.ownerPhone != null && provider.ownerPhone!.isNotEmpty)
              Text(provider.ownerPhone!, style: textTheme.bodySmall),
            if (provider.description != null && provider.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(provider.description!, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${provider.serviceCount} service${provider.serviceCount == 1 ? '' : 's'} listed',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isBusy)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 44),
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
