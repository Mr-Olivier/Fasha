import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/presentation/notification_controller.dart';

/// An AppBar action any top-level (tab-root) screen can show - any role can
/// receive a notification, so this isn't specific to Home's old
/// customer/provider/admin split it started inside.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.read).length ?? 0;

    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        label: Text('$unreadCount'),
        isLabelVisible: unreadCount > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
