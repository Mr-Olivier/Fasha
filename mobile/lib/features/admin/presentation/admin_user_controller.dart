import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/domain/user_role.dart';
import '../data/admin_user_api.dart';
import '../data/admin_user_repository.dart';
import '../domain/account_status.dart';
import '../domain/admin_user.dart';

final adminUserApiProvider = Provider<AdminUserApi>(
  (ref) => AdminUserApi(ref.watch(apiClientProvider).dio),
);

final adminUserRepositoryProvider = Provider<AdminUserRepository>(
  (ref) => AdminUserRepository(ref.watch(adminUserApiProvider)),
);

/// The admin Customers screen's data - `.family` keyed by role so the same
/// provider/cache mechanism could list any role, though only
/// [UserRole.customer] is used today (Providers has its own richer,
/// business-profile-aware list - see adminProvidersByStatusProvider).
final adminUsersByRoleProvider = FutureProvider.family<List<AdminUser>, UserRole>(
  (ref, role) => ref.watch(adminUserRepositoryProvider).list(role: role),
);

/// Suspending/resuming/deleting one account - its own dedicated
/// `AsyncNotifier<bool>` rather than folding into the list providers above,
/// same reasoning as DecideProviderController: an initial list fetch and a
/// successful mutation would otherwise both look like "was loading, now has
/// a value", which is what caused a real false-success-toast bug the first
/// two times this pattern was missed elsewhere in the app.
class AdminAccountActionController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> setStatus({required String userId, required AccountStatus status}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminUserRepositoryProvider).setStatus(userId: userId, status: status);
      return true;
    });
  }

  Future<void> delete(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminUserRepositoryProvider).delete(userId);
      return true;
    });
  }
}

final adminAccountActionControllerProvider =
    AsyncNotifierProvider<AdminAccountActionController, bool>(AdminAccountActionController.new);
