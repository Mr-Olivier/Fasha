import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/provider_profile.dart';
import 'provider_profile_controller.dart';
import 'verification_badge.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Tracks whether we've already copied the loaded profile's values into the
  // text controllers, so we don't stomp on what the user is currently typing
  // every time this widget rebuilds (e.g. while the save request is loading).
  bool _controllersPrefilled = false;

  // Tracks "the user actually pressed Save" - without this, the listener
  // below can't tell that apart from this screen's own initial GET
  // /api/providers/me finishing (both look like "was loading, now has a
  // value" on the very same provider). Set true right before calling
  // save(), consumed (and reset) the moment the listener acts on it.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ProviderProfile? profile) {
    if (_controllersPrefilled || profile == null) return;
    _businessNameController.text = profile.businessName;
    _descriptionController.text = profile.description ?? '';
    _locationController.text = profile.location ?? '';
    _controllersPrefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _isSubmitting = true;
    await ref.read(providerProfileControllerProvider.notifier).save(
          businessName: _businessNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          // Real image upload is out of scope for the MVP (see README.md
          // section 12) - keeping the existing URL unchanged for now.
          profileImageUrl: null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerProfileControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(providerProfileControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        _isSubmitting = false;
        AppToast.apiError(context, error);
        return;
      }
      if (_isSubmitting && next.hasValue && error == null) {
        _isSubmitting = false;
        AppToast.success(context, 'Profile saved.');
      }
    });

    final profile = state.valueOrNull;
    _prefillIfNeeded(profile);
    final isCreating = profile == null;

    return Scaffold(
      appBar: AppBar(title: Text(isCreating ? 'Create your profile' : 'Edit your profile')),
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
                    if (profile != null) VerificationBadge(status: profile.verificationStatus),
                    if (profile != null) const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(labelText: 'Business name'),
                      validator: (value) => Validators.required(value, fieldName: 'Business name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location (optional)'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isCreating ? 'Create profile' : 'Save changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
