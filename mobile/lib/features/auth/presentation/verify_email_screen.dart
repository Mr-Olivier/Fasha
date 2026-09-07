import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import 'auth_controller.dart';
import 'verify_email_controller.dart';

/// Blocks entry to the rest of the app until a fresh registration's email
/// is verified - app_router.dart's redirect sends any logged-in-but-
/// unverified user here and won't let them navigate away until
/// AuthController.applyEmailVerified() flips emailVerified to true.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(verifyEmailControllerProvider.notifier).verify(_codeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authControllerProvider).valueOrNull?.email ?? 'your email';
    final verifyState = ref.watch(verifyEmailControllerProvider);
    final resendState = ref.watch(resendVerificationControllerProvider);
    final isVerifying = verifyState.isLoading;
    final isResending = resendState.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(verifyEmailControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
        return;
      }
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        ref.read(authControllerProvider.notifier).applyEmailVerified();
        AppToast.success(context, 'Email verified.');
      }
    });

    ref.listen(resendVerificationControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
        return;
      }
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        AppToast.success(context, 'A new code was sent.');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Log out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Check your inbox', style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'We sent a 6-digit code to $email. Enter it below to verify your account.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  enabled: !isVerifying,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                  decoration: const InputDecoration(labelText: 'Verification code', counterText: ''),
                  validator: (value) => Validators.required(value, fieldName: 'The code'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isVerifying ? null : _submit,
                  child: isVerifying
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isResending ? null : () => ref.read(resendVerificationControllerProvider.notifier).resend(),
                  child: isResending
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Didn't get a code? Resend"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
