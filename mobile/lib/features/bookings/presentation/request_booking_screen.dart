import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../services/domain/service_listing.dart';
import 'booking_controller.dart';
import 'booking_photo_controller.dart';

/// A customer requesting a specific service from ProviderDetailScreen.
/// [service] arrives via GoRoute's `extra` - same pattern ServiceFormScreen
/// uses for the ServiceListing it's editing.
class RequestBookingScreen extends ConsumerStatefulWidget {
  const RequestBookingScreen({super.key, required this.service});

  final ServiceListing service;

  @override
  ConsumerState<RequestBookingScreen> createState() => _RequestBookingScreenState();
}

class _RequestBookingScreenState extends ConsumerState<RequestBookingScreen> {
  final _noteController = TextEditingController();
  DateTime? _requestedDate;
  final List<XFile> _selectedPhotos = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (image == null) return;
    setState(() => _selectedPhotos.add(image));
  }

  /// Best-effort: the booking itself is already created by the time this
  /// runs, so a photo upload failure here shouldn't block the customer
  /// from moving on - it just means "Photos from customer" stays empty on
  /// the provider's side for this request.
  Future<void> _uploadSelectedPhotos(String bookingId) async {
    final repository = ref.read(bookingPhotoRepositoryProvider);
    for (final photo in _selectedPhotos) {
      try {
        await repository.upload(bookingId, photo);
      } catch (_) {
        // Swallowed deliberately - see this method's doc comment.
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _requestedDate = picked);
  }

  Future<void> _submit() async {
    await ref.read(requestBookingControllerProvider.notifier).submit(
          serviceListingId: widget.service.id,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          requestedDate: _requestedDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestBookingControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(requestBookingControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
        return;
      }
      // Checking the VALUE itself (not just "was loading, now has one") -
      // build() also resolves loading -> AsyncData(false) once, on this
      // screen's very first frame, which is not a successful submission.
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        AppToast.success(context, 'Request sent.');
        final bookingId = ref.read(requestBookingControllerProvider.notifier).lastCreatedBookingId;
        if (bookingId != null && _selectedPhotos.isNotEmpty) {
          unawaited(_uploadSelectedPhotos(bookingId));
        }
        context.go('/bookings');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Request service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.service.name, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'RWF ${widget.service.price.toStringAsFixed(0)}',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              TextField(
                controller: _noteController,
                enabled: !isLoading,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Describe what you need (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _requestedDate == null
                      ? 'Pick a preferred date (optional)'
                      : '${_requestedDate!.year}-${_requestedDate!.month.toString().padLeft(2, '0')}-${_requestedDate!.day.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 16),
              Text('Add photos (optional)', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final photo in _selectedPhotos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.field),
                      child: Image.file(File(photo.path), width: 72, height: 72, fit: BoxFit.cover),
                    ),
                  InkWell(
                    onTap: isLoading ? null : _addPhoto,
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                      child: const SizedBox(height: 72, width: 72, child: Icon(Icons.add_a_photo_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
