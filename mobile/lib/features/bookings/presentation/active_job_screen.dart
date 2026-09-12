import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/call_contact_row.dart';
import '../../../core/widgets/secure_network_image.dart';
import '../domain/booking.dart';
import 'booking_controller.dart';
import 'booking_photo_controller.dart';

/// D3 - a provider's view of a job they've started, reached by tapping
/// "Continue job" on an IN_PROGRESS RequestCard. Lets them leave a work
/// note the customer sees, attach photos of the finished work, and finally
/// mark the job complete.
class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  late final _noteController = TextEditingController(text: widget.booking.workNote ?? '');
  bool _savingNote = false;
  bool _completing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String get _elapsedLabel {
    final elapsed = DateTime.now().difference(widget.booking.updatedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    if (hours <= 0) return '${minutes}m elapsed';
    return '${hours}h${minutes}m elapsed';
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    final notifier = ref.read(incomingRequestsControllerProvider.notifier);
    await notifier.updateWorkNote(widget.booking.id, _noteController.text.trim());
    if (!mounted) return;
    setState(() => _savingNote = false);
    final state = ref.read(incomingRequestsControllerProvider);
    if (state.hasError) {
      AppToast.apiError(context, state.error!);
    } else {
      AppToast.success(context, 'Work note saved.');
    }
  }

  Future<void> _addPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (image == null) return;
    await ref.read(bookingPhotoControllerProvider(widget.booking.id).notifier).upload(image);
  }

  Future<void> _markComplete() async {
    setState(() => _completing = true);
    await ref.read(incomingRequestsControllerProvider.notifier).complete(widget.booking.id);
    if (!mounted) return;
    setState(() => _completing = false);
    final state = ref.read(incomingRequestsControllerProvider);
    if (state.hasError) {
      AppToast.apiError(context, state.error!);
      return;
    }
    AppToast.success(context, 'Job marked as completed.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final photosState = ref.watch(bookingPhotoControllerProvider(booking.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Active job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: StatusColors.positive(context).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadii.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IN PROGRESS', style: textTheme.labelSmall?.copyWith(color: StatusColors.positive(context))),
                    const SizedBox(height: 4),
                    Text(_elapsedLabel, style: textTheme.titleMedium?.copyWith(color: StatusColors.positive(context))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.customerName, style: textTheme.titleMedium),
                          Text(booking.serviceName, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (booking.customerPhone != null)
                      CallContactRow(name: booking.customerName, phone: booking.customerPhone!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text('Work note · customer sees this', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'What did you do?'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: _savingNote ? null : _saveNote,
                child: _savingNote
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save note'),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text('Add photos of the work', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            photosState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Could not load photos.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              data: (photos) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final photo in photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.field),
                      child: SecureNetworkImage(
                        path: '/bookings/${booking.id}/photos/${photo.id}',
                        width: 88,
                        height: 88,
                      ),
                    ),
                  InkWell(
                    onTap: _addPhoto,
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                      child: const SizedBox(height: 88, width: 88, child: Icon(Icons.add_a_photo_outlined)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Marking the job complete asks ${booking.customerName} to confirm and leave a review. '
                  'Payment is settled directly between you.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            FilledButton(
              onPressed: _completing ? null : _markComplete,
              child: _completing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Mark job as completed'),
            ),
          ],
        ),
      ),
    );
  }
}
