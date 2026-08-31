import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import 'change_password_controller.dart';

/// A logged-in user changing their own password from settings - requires
/// their CURRENT password (proving it's really them), unlike the
/// forgot-password flow (features/auth) which is for someone who's locked
/// out and can't log in at all.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(changePasswordControllerProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(changePasswordControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
        return;
      }
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        AppToast.success(context, 'Password changed.');
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (value) => Validators.required(value, fieldName: 'Your current password'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: TextButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      child: Text(_obscure ? 'Show' : 'Hide'),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                  validator: (value) => Validators.confirmPassword(value, _newPasswordController.text),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Change password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
