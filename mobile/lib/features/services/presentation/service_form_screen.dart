import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/service_listing.dart';
import 'category_controller.dart';
import 'service_listing_controller.dart';

/// Shared by both "add a service" and "edit a service" - [existing] being
/// null is what makes this a create form instead of an edit form. Passed
/// via GoRouter's `extra` (see app_router.dart) rather than looked up by an
/// id in the URL, since the caller already has the full object in hand and
/// re-fetching it would just be a wasted round trip.
class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({super.key, this.existing});

  final ServiceListing? existing;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
  late final _priceController =
      TextEditingController(text: widget.existing != null ? widget.existing!.price.toString() : '');
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.existing?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(serviceListingControllerProvider.notifier);
    final price = double.parse(_priceController.text.trim());
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    if (widget.existing == null) {
      await controller.addService(
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        description: description,
        price: price,
      );
    } else {
      await controller.updateService(
        serviceId: widget.existing!.id,
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        description: description,
        price: price,
      );
    }

    // Only pop back to the list on success - if the save failed, the
    // listener below shows the error and the form stays open so the user
    // can fix it and retry, instead of losing what they typed.
    final state = ref.read(serviceListingControllerProvider);
    if (state.hasError) return;
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final isSaving = ref.watch(serviceListingControllerProvider).isLoading;
    final isEditing = widget.existing != null;

    ref.listen(serviceListingControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        final message = error is ApiException ? error.message : 'Something went wrong.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit service' : 'Add service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              categoriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Could not load categories: $error'),
                data: (categories) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(value: category.id, child: Text(category.name)),
                  ],
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) => value == null ? 'Choose a category' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price', prefixText: 'RWF '),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a valid price';
                  if (parsed < 0) return 'Price cannot be negative';
                  return null;
                },
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
                    : Text(isEditing ? 'Save changes' : 'Add service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
