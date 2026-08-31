import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../bookings/domain/booking.dart';
import 'review_controller.dart';

/// A customer reviewing one of their own COMPLETED bookings. [booking]
/// arrives via GoRoute's `extra` - same pattern RequestBookingScreen uses
/// for the ServiceListing it's requesting.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;

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
        AppToast.success(context, 'Thanks for your review!');
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a review')),
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
                      Text(widget.booking.serviceName, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('with ${widget.booking.providerBusinessName}', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text('How was your experience?', style: textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.gutter),
              TextField(
                controller: _commentController,
                enabled: !isLoading,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Add a comment (optional)',
                  alignLabelWithHint: true,
                ),
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
}
