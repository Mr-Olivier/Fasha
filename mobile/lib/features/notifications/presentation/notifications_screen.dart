import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/app_notification.dart';
import 'notification_controller.dart';

/// F1 in fasha-app-final-ui.html - TODAY/EARLIER grouped list. Reached from
/// the bell icon on HomeScreen's app bar (visible to every role, since any
/// role can receive a notification).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final actionsState = ref.watch(notificationActionsControllerProvider);

    ref.listen(notificationActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    final hasUnread = notificationsState.valueOrNull?.any((n) => !n.read) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: actionsState.isLoading
                  ? null
                  : () => ref.read(notificationActionsControllerProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load notifications.')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'Nothing here yet. We\'ll let you know when something about your bookings changes.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }

          final today = _todaysNotifications(notifications);
          final earlier = notifications.skip(today.length).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                if (today.isNotEmpty) ...[
                  _SectionHeader('TODAY'),
                  for (final notification in today) _NotificationTile(notification: notification),
                ],
                if (earlier.isNotEmpty) ...[
                  _SectionHeader('EARLIER'),
                  for (final notification in earlier) _NotificationTile(notification: notification),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Notifications are already newest-first from the backend, so "today's"
  /// ones are simply the leading run whose date matches today's.
  List<AppNotification> _todaysNotifications(List<AppNotification> notifications) {
    final now = DateTime.now();
    bool isToday(DateTime date) => date.year == now.year && date.month == now.month && date.day == now.day;
    final result = <AppNotification>[];
    for (final notification in notifications) {
      if (!isToday(notification.createdAt.toLocal())) break;
      result.add(notification);
    }
    return result;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
        child: Icon(
          Icons.notifications_outlined,
          color: notification.read ? colorScheme.onSurfaceVariant : colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: textTheme.titleMedium?.copyWith(fontWeight: notification.read ? FontWeight.w500 : FontWeight.w800),
      ),
      subtitle: Text(notification.body, style: textTheme.bodyMedium),
      trailing: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
            ),
      onTap: notification.read
          ? null
          : () => ref.read(notificationActionsControllerProvider.notifier).markRead(notification.id),
    );
  }
}
