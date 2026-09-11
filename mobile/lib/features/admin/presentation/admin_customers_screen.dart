import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/domain/user_role.dart';
import '../domain/account_status.dart';
import '../domain/admin_user.dart';
import 'account_actions_menu.dart';
import 'admin_user_controller.dart';

/// Admin's customer account list - lets an admin suspend/resume/delete a
/// customer's account, same shape as AdminProvidersScreen's now-extended
/// card actions (see AccountActionsMenu, shared by both).
class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  // Tracks which row's action is in flight, so only THAT row shows a
  // spinner - adminAccountActionControllerProvider only holds one
  // in-flight mutation at a time, not which account it belongs to.
  String? _busyUserId;

  Future<void> _handle(AdminUser user, AccountAction action) async {
    if (action == AccountAction.delete) {
      final confirmed = await confirmDeleteAccount(context, user.name);
      if (!confirmed) return;
    }

    _busyUserId = user.userId;
    final controller = ref.read(adminAccountActionControllerProvider.notifier);
    if (action == AccountAction.delete) {
      await controller.delete(user.userId);
    } else {
      await controller.setStatus(
        userId: user.userId,
        status: action == AccountAction.suspend ? AccountStatus.suspended : AccountStatus.active,
      );
    }

    if (!mounted) return;
    final state = ref.read(adminAccountActionControllerProvider);
    if (state.hasError) return; // the listener below shows the error toast
    ref.invalidate(adminUsersByRoleProvider(UserRole.customer));
    AppToast.success(context, switch (action) {
      AccountAction.suspend => 'Account suspended.',
      AccountAction.resume => 'Account resumed.',
      AccountAction.delete => 'Account deleted.',
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersByRoleProvider(UserRole.customer));
    final actionState = ref.watch(adminAccountActionControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(adminAccountActionControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        _busyUserId = null;
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: usersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load customers.')),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No customers yet.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminUsersByRoleProvider(UserRole.customer).future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final user = users[index];
                final isBusy = actionState.isLoading && _busyUserId == user.userId;
                return _CustomerRow(
                  user: user,
                  isBusy: isBusy,
                  onAction: (action) => _handle(user, action),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.user, required this.isBusy, required this.onAction});

  final AdminUser user;
  final bool isBusy;
  final ValueChanged<AccountAction> onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final suspended = user.status == AccountStatus.suspended;
    final statusColor = suspended ? StatusColors.negative(context) : StatusColors.positive(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: suspended ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
              foregroundColor: suspended ? colorScheme.onSurfaceVariant : colorScheme.primary,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    Text(
                      user.phone!,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  const SizedBox(height: 4),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      child: Text(
                        suspended ? 'SUSPENDED' : 'ACTIVE',
                        style: textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                height: 24,
                width: 24,
                child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              AccountActionsMenu(status: user.status, onSelected: onAction),
          ],
        ),
      ),
    );
  }
}
