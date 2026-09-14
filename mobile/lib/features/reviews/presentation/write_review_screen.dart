import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../bookings/domain/booking.dart';
import '../domain/review_tag.dart';
import 'review_controller.dart';

/// A customer reviewing one of their own COMPLETED bookings (mockup screen
/// C6). [booking] arrives via GoRoute's `extra` - same pattern
/// RequestBookingScreen uses for the ServiceListing it's requesting.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  final Set<ReviewTag> _tags = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppToast.error(context, 'Tap a star to rate your experience.');
      return;
    }
    await ref.read(submitReviewControllerProvider.notifier).submit(
          bookingId: widget.booking.id,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          tags: _tags,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submitReviewControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(submitReviewControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
        return;
      }
      // Checking the VALUE itself, not just "was loading, now has one" -
      // see RequestBookingController's doc comment for why that heuristic
      // alone isn't safe on a provider whose build() also resolves once.
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        context.pushReplacement(
          '/review-posted',
          extra: (booking: widget.booking, rating: _rating),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Rate this job')),
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
                      Text(widget.booking.providerBusinessName, style: textTheme.titleLarge),
                      Text('${widget.booking.serviceName} · completed', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      iconSize: 40,
                      onPressed: isLoading ? null : () => setState(() => _rating = star),
                      icon: Icon(
                        _rating >= star ? Icons.star : Icons.star_border,
                        color: colorScheme.secondary,
                      ),
                    ),
                ],
              ),
              if (_rating > 0)
                Center(
                  child: Text(_ratingLabel(_rating), style: textTheme.titleMedium, textAlign: TextAlign.center),
                ),
              const SizedBox(height: AppSpacing.gutter),
              Text('What stood out?', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in ReviewTag.values)
                    FilterChip(
                      label: Text(tag.label),
                      selected: _tags.contains(tag),
                      onSelected: isLoading
                          ? null
                          : (selected) => setState(() => selected ? _tags.add(tag) : _tags.remove(tag)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text('Comment · optional', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _commentController,
                enabled: !isLoading,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(hintText: 'Tell other customers how it went...'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int stars) => switch (stars) {
        1 => 'Poor — 1 of 5',
        2 => 'Fair — 2 of 5',
        3 => 'Okay — 3 of 5',
        4 => 'Good job — 4 of 5',
        _ => 'Excellent — 5 of 5',
      };
}
