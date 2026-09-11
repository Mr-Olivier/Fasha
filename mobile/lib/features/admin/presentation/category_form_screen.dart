import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../../services/domain/category.dart';
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
      await controller.addCategory(name: name, description: description);
    } else {
      await controller.updateCategory(categoryId: widget.existing!.id, name: name, description: description);
    }

    // Only pop back to the list on success - if the save failed, the
    // listener below shows the error and the form stays open so the user
    // can fix it and retry, instead of losing what they typed.
    final state = ref.read(adminCategoryControllerProvider);
    if (state.hasError) return;
    if (!mounted) return;
    AppToast.success(context, widget.existing == null ? 'Category added.' : 'Category updated.');
    context.pop();
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
