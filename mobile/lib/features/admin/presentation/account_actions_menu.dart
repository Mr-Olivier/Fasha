import 'package:flutter/material.dart';

import '../domain/account_status.dart';

enum AccountAction { suspend, resume, delete }

/// The suspend/resume/delete overflow menu shared by AdminCustomersScreen
/// and AdminProvidersScreen - "manage an account" looks the same
/// regardless of which role it belongs to (see AdminUserController on the
/// backend, which is exactly as role-agnostic).
class AccountActionsMenu extends StatelessWidget {
  const AccountActionsMenu({super.key, required this.status, required this.onSelected, this.enabled = true});

  final AccountStatus status;
  final ValueChanged<AccountAction> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<AccountAction>(
      enabled: enabled,
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        if (status == AccountStatus.active)
          const PopupMenuItem(
            value: AccountAction.suspend,
            child: ListTile(leading: Icon(Icons.pause_circle_outline), title: Text('Suspend'), contentPadding: EdgeInsets.zero),
          )
        else
          const PopupMenuItem(
            value: AccountAction.resume,
            child: ListTile(leading: Icon(Icons.play_circle_outline), title: Text('Resume'), contentPadding: EdgeInsets.zero),
          ),
        PopupMenuItem(
          value: AccountAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text('Delete account', style: TextStyle(color: colorScheme.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Shared "are you sure?" confirmation for AccountAction.delete - a
/// permanent action, unlike suspend/resume, so it always gets an extra
/// confirmation step, matching AdminCategoriesScreen/CategoryFormScreen's
/// own delete-confirmation dialogs.
Future<bool> confirmDeleteAccount(BuildContext context, String accountLabel) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete account?'),
      content: Text('"$accountLabel" will be permanently removed. This can\'t be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
      ],
    ),
  );
  return confirmed ?? false;
}
