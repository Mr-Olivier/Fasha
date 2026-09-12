import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../../services/presentation/category_controller.dart';
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
  final _experienceController = TextEditingController();
  String? _selectedCategoryId;

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
    _experienceController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ProviderProfile? profile) {
    if (_controllersPrefilled || profile == null) return;
    _businessNameController.text = profile.businessName;
    _descriptionController.text = profile.description ?? '';
    _locationController.text = profile.location ?? '';
    _experienceController.text = profile.yearsExperience?.toString() ?? '';
    _selectedCategoryId = profile.categoryId;
    _controllersPrefilled = true;
  }

  Future<void> _pickAndUploadPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (image == null) return;
    await ref.read(providerProfileControllerProvider.notifier).uploadPhoto(image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _isSubmitting = true;
    final experienceText = _experienceController.text.trim();
    await ref.read(providerProfileControllerProvider.notifier).save(
          businessName: _businessNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          // The photo has its own dedicated upload button/endpoint - saving
          // the rest of the form must never overwrite it, so this is always
          // whatever the currently-loaded profile already has.
          profileImageUrl: ref.read(providerProfileControllerProvider).valueOrNull?.profileImageUrl,
          categoryId: _selectedCategoryId,
          yearsExperience: experienceText.isEmpty ? null : int.parse(experienceText),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerProfileControllerProvider);
    final isLoading = state.isLoading;
    final categoriesState = ref.watch(categoriesProvider);

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
      appBar: AppBar(
        title: Text(isCreating ? 'Create your profile' : 'Edit your profile'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
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
                    if (profile != null) ...[
                      VerificationBadge(status: profile.verificationStatus),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          children: [
                            _ProfilePhoto(profile: profile),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: isLoading ? null : _pickAndUploadPhoto,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(labelText: 'Business name'),
                      validator: (value) => Validators.required(value, fieldName: 'Business name'),
                    ),
                    const SizedBox(height: 16),
                    categoriesState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text('Could not load categories: $error'),
                      data: (categories) => DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category (optional)'),
                        items: [
                          for (final category in categories)
                            DropdownMenuItem(value: category.id, child: Text(category.name)),
                        ],
                        onChanged: (value) => setState(() => _selectedCategoryId = value),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location (optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Years of experience (optional)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return int.tryParse(value.trim()) == null ? 'Enter a whole number' : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'About your work (optional)'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.profile});

  final ProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.profileImageUrl;
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 48,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      // StaticResourceConfig serves this at the backend's plain host, not
      // under "/api" - see ApiClient.mediaBaseUrl's doc comment.
      backgroundImage: imageUrl != null ? NetworkImage('${ApiClient.mediaBaseUrl}$imageUrl') : null,
      child: imageUrl == null
          ? Text(
              profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}
