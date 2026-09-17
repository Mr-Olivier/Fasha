import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../../services/domain/category.dart';
import '../../services/presentation/category_icon_badge.dart';
import 'admin_category_controller.dart';

/// Shared by both "add a category" and "edit a category" - [existing] being
/// null is what makes this a create form instead of an edit form, same
/// convention as ServiceFormScreen.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.existing});

  final Category? existing;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.existing?.description ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(adminCategoryControllerProvider.notifier);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    if (widget.existing == null) {
      final created = await controller.addCategory(name: name, description: description);
      final state = ref.read(adminCategoryControllerProvider);
      if (state.hasError || created == null) return;
      if (!mounted) return;
      AppToast.success(context, 'Category added.');
      // Straight into editing the category just created - that's where
      // the icon-upload UI lives (see _CategoryImageSection's doc
      // comment), so adding a custom icon is the natural next step
      // instead of a separate trip back into the list to find it again.
      context.pushReplacement('/admin/categories/form', extra: created);
      return;
    }

    await controller.updateCategory(categoryId: widget.existing!.id, name: name, description: description);

    // Only pop back to the list on success - if the save failed, the
    // listener below shows the error and the form stays open so the user
    // can fix it and retry, instead of losing what they typed.
    final state = ref.read(adminCategoryControllerProvider);
    if (state.hasError) return;
    if (!mounted) return;
    AppToast.success(context, 'Category updated.');
    context.pop();
  }

  /// Same direct-to-gallery pattern ProfileScreen's own avatar upload uses
  /// (no bottom sheet - an admin picking a category icon isn't the "snap a
  /// photo of a problem" scenario chat's camera option exists for). Only
  /// reachable once [widget.existing] is non-null (see build()'s "editing
  /// only" guard) - a category needs to exist server-side before there's
  /// an id to upload against, same as an avatar needing an account first.
  Future<void> _pickAndUploadImage() async {
    final categoryId = widget.existing?.id;
    if (categoryId == null) return;

    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (image == null || !mounted) return;

    await ref.read(adminCategoryControllerProvider.notifier).uploadImage(categoryId: categoryId, file: image);
    final state = ref.read(adminCategoryControllerProvider);
    if (state.hasError || !mounted) return;
    AppToast.success(context, 'Icon updated.');
  }

  Future<void> _removeImage() async {
    final categoryId = widget.existing?.id;
    if (categoryId == null) return;

    await ref.read(adminCategoryControllerProvider.notifier).removeImage(categoryId);
    final state = ref.read(adminCategoryControllerProvider);
    if (state.hasError || !mounted) return;
    AppToast.success(context, 'Reset to the default icon.');
  }

  Future<void> _delete() async {
    final category = widget.existing;
    if (category == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${category.name}" will be removed. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(adminCategoryControllerProvider.notifier).deleteCategory(category.id);

    final state = ref.read(adminCategoryControllerProvider);
    if (state.hasError) return;
    if (!mounted) return;
    AppToast.success(context, 'Category deleted.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(adminCategoryControllerProvider).isLoading;
    final isEditing = widget.existing != null;

    ref.listen(adminCategoryControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit category' : 'Add category')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category name'),
                validator: (value) => Validators.required(value, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 24),
                _CategoryImageSection(
                  category: widget.existing!,
                  isBusy: isSaving,
                  onUpload: _pickAndUploadImage,
                  onRemove: _removeImage,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Save changes' : 'Add category'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isSaving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  child: const Text('Delete category'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon an admin sets for this category - shows what customers
/// actually see today (falling back through to CategoryStyle's default the
/// same way CategoryIconBadge does everywhere else) rather than assuming
/// [category]'s own possibly-stale imageUrl, since a controller
/// upload/remove call updates the LIST this screen was opened from, not
/// this widget's original constructor argument.
class _CategoryImageSection extends ConsumerWidget {
  const _CategoryImageSection({
    required this.category,
    required this.isBusy,
    required this.onUpload,
    required this.onRemove,
  });

  final Category category;
  final bool isBusy;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final categories = ref.watch(adminCategoryControllerProvider).valueOrNull ?? const [];
    final matches = categories.where((c) => c.id == category.id);
    final currentImageUrl = matches.isEmpty ? category.imageUrl : matches.first.imageUrl;
    final preview = Category(id: category.id, name: category.name, imageUrl: currentImageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category icon', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Shown everywhere this category appears in the app. Leave it '
          'unset to use the default icon instead.',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            InkWell(
              onTap: isBusy ? null : onUpload,
              borderRadius: BorderRadius.circular(AppRadii.field),
              child: SizedBox(
                width: 72,
                height: 72,
                child: CategoryIconBadge(category: preview, iconSize: 32),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: isBusy ? null : onUpload,
                    child: Text(currentImageUrl == null ? 'Upload icon' : 'Change icon'),
                  ),
                  if (currentImageUrl != null)
                    TextButton(
                      onPressed: isBusy ? null : onRemove,
                      child: const Text('Reset to default'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
