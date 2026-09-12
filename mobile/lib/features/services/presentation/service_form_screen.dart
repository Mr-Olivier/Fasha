import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/service_duration.dart';
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
  late ServiceDuration _duration;
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.existing?.categoryId;
    _duration = widget.existing?.duration ?? ServiceDuration.oneToTwoHours;
    _visible = widget.existing?.visible ?? true;
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
        duration: _duration,
        visible: _visible,
      );
    } else {
      await controller.updateService(
        serviceId: widget.existing!.id,
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        description: description,
        price: price,
        duration: _duration,
        visible: _visible,
      );
    }

    // Only pop back to the list on success - if the save failed, the
    // listener below shows the error and the form stays open so the user
    // can fix it and retry, instead of losing what they typed.
    final state = ref.read(serviceListingControllerProvider);
    if (state.hasError) return;
    if (!mounted) return;
    AppToast.success(context, widget.existing == null ? 'Service added.' : 'Service updated.');
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
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit service' : 'Add service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                validator: (value) => Validators.required(value, fieldName: 'Name'),
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
                validator: Validators.price,
              ),
              const SizedBox(height: 16),
              Text('Duration', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final option in ServiceDuration.values)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: _duration == option,
                      onSelected: (_) => setState(() => _duration = option),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in search'),
                subtitle: const Text('Turn off to pause bookings'),
                value: _visible,
                onChanged: (value) => setState(() => _visible = value),
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
