import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/notification_api.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(apiClientProvider).dio),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(notificationApiProvider)),
);

/// Polled on demand (screen open / pull-to-refresh) - there's no push
/// wiring, so this is the app's only source of truth for what's new.
final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).list(),
);

/// Marking one or all notifications read - its own dedicated
/// `AsyncNotifier<bool>` so an error surfaces cleanly via ref.listen,
/// same pattern as every other one-shot action in this app.
class NotificationActionsController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> markRead(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationRepositoryProvider).markRead(id);
      ref.invalidate(notificationsProvider);
      return true;
    });
  }

  Future<void> markAllRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      return true;
    });
  }
}

final notificationActionsControllerProvider =
    AsyncNotifierProvider<NotificationActionsController, bool>(NotificationActionsController.new);
