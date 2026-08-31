import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_profile_controller.dart';

/// Changes the logged-in user's password (they type their current one to
/// prove it's really them - see ChangePasswordScreen). Separate from the
/// forgot/reset-password flow in the auth feature: that's for a locked-out,
/// LOGGED-OUT user; this is a normal, logged-in settings action.
///
/// State is just "has this succeeded yet" - same true-once-on-success shape
/// as auth's ResetPasswordController.
class ChangePasswordController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      return true;
    });
  }
}

final changePasswordControllerProvider =
    AsyncNotifierProvider<ChangePasswordController, bool>(ChangePasswordController.new);
