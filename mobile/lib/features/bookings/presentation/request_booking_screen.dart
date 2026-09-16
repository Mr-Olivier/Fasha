import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/picked_image_preview.dart';
import '../../services/domain/service_listing.dart';
import '../domain/time_window.dart';
import 'booking_controller.dart';
import 'booking_photo_controller.dart';

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// A customer requesting a specific service from ProviderDetailScreen
/// (mockup screen B7) - a 2-step wizard (Job Details, then Schedule &
/// Location), matching the design reference's own "Step 1/2"/"Step 2/2"
/// request flow rather than one long scrolling form. [service] arrives via
/// GoRoute's `extra` - same pattern ServiceFormScreen uses for the
/// ServiceListing it's editing.
class RequestBookingScreen extends ConsumerStatefulWidget {
  const RequestBookingScreen({super.key, required this.service});

  final ServiceListing service;

  @override
  ConsumerState<RequestBookingScreen> createState() => _RequestBookingScreenState();
}

class _RequestBookingScreenState extends ConsumerState<RequestBookingScreen> {
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _requestedDate;
  TimeWindow? _timeWindow;
  final List<XFile> _selectedPhotos = [];
  int _step = 0;

  @override
  void dispose() {
    _noteController.dispose();
    _addressController.dispose();
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
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          timeWindow: _timeWindow,
        );
  }

  String _formatDate(DateTime date) => '${_weekdayNames[date.weekday - 1]} ${_monthNames[date.month - 1]} ${date.day}';

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
        final booking = ref.read(requestBookingControllerProvider.notifier).lastCreatedBooking;
        if (booking != null && _selectedPhotos.isNotEmpty) {
          unawaited(_uploadSelectedPhotos(booking.id));
        }
        if (booking != null) context.pushReplacement('/request-sent', extra: booking);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 0) {
              context.pop();
            } else {
              setState(() => _step = 0);
            }
          },
        ),
        title: Text('Step ${_step + 1} of 2'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ClipRRect(
              child: LinearProgressIndicator(
                value: (_step + 1) / 2,
                minHeight: 3,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: _step == 0 ? _jobDetailsStep(isLoading, textTheme, colorScheme) : _scheduleStep(isLoading, textTheme, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobDetailsStep(bool isLoading, TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Job details', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.service.name, style: textTheme.titleLarge),
                      Text(widget.service.duration.label, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  'RWF ${widget.service.price.toStringAsFixed(0)}',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Text('Describe the job', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _noteController,
          enabled: !isLoading,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Photos', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Clear photos help the provider bring the right tools and quote accurately.',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final photo in _selectedPhotos)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.field),
                child: PickedImagePreview(file: photo, width: 72, height: 72),
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
        const SizedBox(height: AppSpacing.gutter),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Next: Schedule'),
        ),
      ],
    );
  }

  Widget _scheduleStep(bool isLoading, TextTheme textTheme, ColorScheme colorScheme) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Schedule & location', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.gutter),
        Text('Preferred date', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final option in [(today, 'Today'), (tomorrow, 'Tomorrow'), (dayAfter, _formatDate(dayAfter))])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(option.$2),
                    selected: _requestedDate != null && _isSameDate(_requestedDate!, option.$1),
                    onSelected: isLoading ? null : (_) => setState(() => _requestedDate = option.$1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: isLoading ? null : _pickDate,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(
            _requestedDate == null || [today, tomorrow, dayAfter].any((d) => _isSameDate(d, _requestedDate!))
                ? 'Pick another date'
                : 'Picked: ${_formatDate(_requestedDate!)}',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Time window', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final window in TimeWindow.values) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(window.label),
                    selected: _timeWindow == window,
                    onSelected: isLoading ? null : (selected) => setState(() => _timeWindow = selected ? window : null),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Job location', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _addressController,
          enabled: !isLoading,
          decoration: const InputDecoration(hintText: 'e.g. KK 15 Ave, Kicukiro (optional)'),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  Text(
                    'RWF ${widget.service.price.toStringAsFixed(0)}',
                    style: textTheme.titleLarge,
                  ),
                ],
              ),
              const Spacer(),
              // See ProviderDetailScreen's identical fix: the theme's
              // full-width FilledButton breaks as a bare Row child.
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send request'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
