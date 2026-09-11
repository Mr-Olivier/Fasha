import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../providers/domain/verification_status.dart';
import '../domain/account_status.dart';
import '../domain/pending_provider.dart';
import 'account_actions_menu.dart';
import 'admin_provider_controller.dart';
import 'admin_user_controller.dart';

/// Admin's provider management screen - a status filter (defaulting to
/// "All") over every provider account, combining what used to be a
/// PENDING-only approval queue with full account management (suspend/
/// resume/delete, via AccountActionsMenu) so a bottom-nav "Providers" tab
/// has one screen that covers both "review new applications" and "manage
/// any provider". Matches the design reference's "Review application"
/// screen (E2) card layout.
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
  String? _busyAccountUserId;
  VerificationStatus? _filter;

  Future<void> _decide(PendingProvider provider, bool approved) async {
    _busyProviderId = provider.id;
    await ref.read(decideProviderControllerProvider.notifier).decide(providerId: provider.id, approved: approved);
    ref.invalidate(adminProvidersByStatusProvider(_filter));
  }

  Future<void> _handleAccountAction(PendingProvider provider, AccountAction action) async {
    if (action == AccountAction.delete) {
      final confirmed = await confirmDeleteAccount(context, provider.ownerName);
      if (!confirmed) return;
    }

    _busyAccountUserId = provider.ownerUserId;
    final controller = ref.read(adminAccountActionControllerProvider.notifier);
    if (action == AccountAction.delete) {
      await controller.delete(provider.ownerUserId);
    } else {
      await controller.setStatus(
        userId: provider.ownerUserId,
        status: action == AccountAction.suspend ? AccountStatus.suspended : AccountStatus.active,
      );
    }

    if (!mounted) return;
    final state = ref.read(adminAccountActionControllerProvider);
    if (state.hasError) return; // the listener below shows the error toast
    ref.invalidate(adminProvidersByStatusProvider(_filter));
    AppToast.success(context, switch (action) {
      AccountAction.suspend => 'Provider suspended.',
      AccountAction.resume => 'Provider resumed.',
      AccountAction.delete => 'Provider account deleted.',
    });
  }

  @override
  Widget build(BuildContext context) {
    final providersState = ref.watch(adminProvidersByStatusProvider(_filter));
    // Watched (not just listened to) so this widget actually rebuilds when
    // it changes - see EditProfileScreen's identical isSubmitting pattern
    // for why that matters.
    final decideState = ref.watch(decideProviderControllerProvider);
    final accountActionState = ref.watch(adminAccountActionControllerProvider);
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

    ref.listen(adminAccountActionControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        _busyAccountUserId = null;
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Providers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in const [
                    (null, 'All'),
                    (VerificationStatus.pending, 'Pending'),
                    (VerificationStatus.approved, 'Approved'),
                    (VerificationStatus.rejected, 'Rejected'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(entry.$2),
                        selected: _filter == entry.$1,
                        onSelected: (_) => setState(() => _filter = entry.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: providersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const Center(child: Text('Could not load providers.')),
              data: (providers) {
                if (providers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      child: Text(
                        _filter == VerificationStatus.pending
                            ? 'No pending applications. New provider sign-ups will show up here for review.'
                            : 'No providers here yet.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(adminProvidersByStatusProvider(_filter).future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    itemCount: providers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      final isBusyDeciding = decideState.isLoading && _busyProviderId == provider.id;
                      final isBusyAccount = accountActionState.isLoading && _busyAccountUserId == provider.ownerUserId;
                      return _ProviderCard(
                        provider: provider,
                        isBusyDeciding: isBusyDeciding,
                        isBusyAccount: isBusyAccount,
                        onApprove: isBusyDeciding ? null : () => _decide(provider, true),
                        onReject: isBusyDeciding ? null : () => _decide(provider, false),
                        onAccountAction: (action) => _handleAccountAction(provider, action),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.isBusyDeciding,
    required this.isBusyAccount,
    required this.onApprove,
    required this.onReject,
    required this.onAccountAction,
  });

  final PendingProvider provider;
  final bool isBusyDeciding;
  final bool isBusyAccount;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<AccountAction> onAccountAction;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final suspended = provider.ownerAccountStatus == AccountStatus.suspended;
    final (statusLabel, statusColor) = suspended
        ? ('Account suspended', StatusColors.negative(context))
        : switch (provider.verificationStatus) {
            VerificationStatus.pending => ('Pending review', StatusColors.pending(context)),
            VerificationStatus.approved => ('Approved', StatusColors.positive(context)),
            VerificationStatus.rejected => ('Rejected', StatusColors.negative(context)),
          };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: suspended ? 0.7 : 1,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isBusyAccount)
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    AccountActionsMenu(status: provider.ownerAccountStatus, onSelected: onAccountAction),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.primary,
                    child: Text(
                      provider.businessName.isNotEmpty ? provider.businessName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provider.businessName, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          [provider.location, 'applied ${_formatDate(provider.appliedAt)}']
                              .where((part) => part != null && part.isNotEmpty)
                              .join(' · '),
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(label: 'Owner', value: provider.ownerName),
              if (provider.ownerPhone != null && provider.ownerPhone!.isNotEmpty)
                _InfoRow(label: 'Phone', value: provider.ownerPhone!),
              _InfoRow(label: 'Email', value: provider.ownerEmail),
              _InfoRow(label: 'Applied', value: _formatDate(provider.appliedAt)),
              _InfoRow(label: 'Services listed', value: '${provider.serviceCount}'),
              if (provider.description != null && provider.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Description', style: textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(provider.description!, style: textTheme.bodyMedium),
              ],
              if (provider.verificationStatus == VerificationStatus.pending) ...[
                const SizedBox(height: AppSpacing.md),
                if (isBusyDeciding)
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
            ],
          ),
        ),
      ),
    );
  }
}

/// One label/value line in the provider detail's key-value block (Owner,
/// Phone, Email, Applied, Services listed) - matches the design's
/// "Review application" screen layout.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
