import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// Spending the EMAIL_VERIFICATION code register() emails out. State is
/// just "has this succeeded yet" - VerifyEmailScreen's cue to call
/// AuthController.applyEmailVerified() once it flips true, same pattern as
/// ResetPasswordController.
class VerifyEmailController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> verify(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).verifyEmail(code: code);
      return true;
    });
  }
}

final verifyEmailControllerProvider =
    AsyncNotifierProvider<VerifyEmailController, bool>(VerifyEmailController.new);

/// Requesting a fresh code when the original expired or never arrived -
/// its own controller for the same reason RequestBookingController is
/// separate from the list it sits next to (see that class's doc comment):
/// this state would otherwise be ambiguous with VerifyEmailController's
/// own "did my code submission succeed" state if they shared one provider.
class ResendVerificationController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> resend() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resendVerification();
      return true;
    });
  }
}

final resendVerificationControllerProvider =
    AsyncNotifierProvider<ResendVerificationController, bool>(ResendVerificationController.new);
