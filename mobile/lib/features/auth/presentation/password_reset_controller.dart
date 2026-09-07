import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/password_reset_result.dart';
import 'auth_controller.dart';

/// Step 1 of the reset flow: request an OTP code for an email address.
///
/// Deliberately a separate controller from [AuthController] - that class's
/// state means "who is logged in right now", and requesting a password
/// reset has nothing to do with the current session (it can be submitted
/// while logged out, for an email that isn't even the current user's).
class ForgotPasswordController extends AsyncNotifier<ForgotPasswordResult?> {
  @override
  Future<ForgotPasswordResult?> build() async => null;

  Future<void> requestReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).forgotPassword(email: email),
    );
  }
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, ForgotPasswordResult?>(ForgotPasswordController.new);

/// Step 2: spend an OTP code to set a new password.
///
/// State is just "has this succeeded yet" - it flips to true once
/// resetPassword() completes, which is ResetPasswordScreen's cue to
/// navigate back to /login.
class ResetPasswordController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resetPassword(email: email, code: code, newPassword: newPassword);
      return true;
    });
  }
}

final resetPasswordControllerProvider =
    AsyncNotifierProvider<ResetPasswordController, bool>(ResetPasswordController.new);
