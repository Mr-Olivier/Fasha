import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import 'password_reset_controller.dart';

/// Step 2 of the reset flow: spend a token (from ForgotPasswordScreen, or
/// in a real deployment from an emailed link) to set a new password.
///
/// [prefilledToken] pre-fills the token field when arriving straight from
/// ForgotPasswordScreen's dev-mode token; the field stays editable because
/// a real user would be typing/pasting a token from an email instead.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.prefilledToken});

  final String? prefilledToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _tokenController = TextEditingController(text: widget.prefilledToken);
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(resetPasswordControllerProvider.notifier).resetPassword(
          token: _tokenController.text.trim(),
          newPassword: _newPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(resetPasswordControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        final message = error is ApiException ? error.message : 'Something went wrong.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      // Flips from false -> true exactly once, the moment resetPassword()
      // succeeds - that's our cue to leave this screen and let the user
      // log in with the password they just set.
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. Please log in with your new password.')),
        );
        context.go('/login');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Set a new password', style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Paste the reset token you were given, then choose a new password.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _tokenController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(labelText: 'Reset token'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'The reset token is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  enabled: !isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: TextButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Text(_obscurePassword ? 'Show' : 'Hide'),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'A new password is required';
                    if (value.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                  validator: (value) {
                    if (value != _newPasswordController.text) return 'Passwords don\'t match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Reset password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
