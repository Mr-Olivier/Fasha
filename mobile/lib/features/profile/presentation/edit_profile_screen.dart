import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/user_account.dart';
import 'user_profile_controller.dart';

/// Editing "name" and "phone" - the only two account fields this MVP lets
/// a user change themselves. Email is intentionally left out: it's the
/// login identifier, and there's no email-verification flow yet to safely
/// let it change (see UpdateProfileRequest's doc comment on the backend).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Same reasoning as ProviderProfileScreen: only copy the loaded account
  // into the text controllers once, so we don't overwrite what the user is
  // currently typing on every rebuild (e.g. while saving).
  bool _controllersPrefilled = false;

  // Tracks "the user actually pressed Save" - without this, the listener
  // below can't tell that apart from this screen's own initial GET
  // /api/users/me finishing (both look like "was loading, now has a
  // value" on the very same provider). Set true right before calling
  // updateProfile(), consumed (and reset) the moment the listener acts on it.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(UserAccount? account) {
    if (_controllersPrefilled || account == null) return;
    _nameController.text = account.name;
    _phoneController.text = account.phone ?? '';
    _controllersPrefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _isSubmitting = true;
    await ref.read(userProfileControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(userProfileControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        _isSubmitting = false;
        AppToast.apiError(context, error);
        return;
      }
      if (_isSubmitting && next.hasValue && error == null) {
        _isSubmitting = false;
        AppToast.success(context, 'Profile updated.');
      }
    });

    final account = state.valueOrNull;
    _prefillIfNeeded(account);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: state.isLoading && !_controllersPrefilled
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) => Validators.required(value, fieldName: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
