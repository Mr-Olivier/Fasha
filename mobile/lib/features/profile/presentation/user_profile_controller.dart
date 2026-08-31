import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/user_api.dart';
import '../data/user_repository.dart';
import '../domain/user_account.dart';

final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.watch(apiClientProvider).dio),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(userApiProvider)),
);

/// Loads and edits the logged-in user's own account (name, phone, avatar).
///
/// build() fetches GET /api/users/me once - AuthUser (from login/register)
/// doesn't carry phone/profileImageUrl, so this is what fills those in the
/// first time ProfileScreen is opened. Every successful mutation also
/// calls AuthController.applyAccountUpdate, so the rest of the app (e.g.
/// HomeScreen's greeting) sees the edit immediately too.
class UserProfileController extends AsyncNotifier<UserAccount?> {
  @override
  Future<UserAccount?> build() async {
    final account = await ref.read(userRepositoryProvider).getMe();
    _syncAuthUser(account);
    return account;
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final account = await ref.read(userRepositoryProvider).updateProfile(name: name, phone: phone);
      _syncAuthUser(account);
      return account;
    });
  }

  Future<void> uploadAvatar(XFile image) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final account = await ref.read(userRepositoryProvider).uploadAvatar(image);
      _syncAuthUser(account);
      return account;
    });
  }

  void _syncAuthUser(UserAccount account) {
    ref.read(authControllerProvider.notifier).applyAccountUpdate(
          name: account.name,
          phone: account.phone,
          profileImageUrl: account.profileImageUrl,
        );
  }
}

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserAccount?>(UserProfileController.new);
