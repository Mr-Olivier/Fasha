import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/booking.dart';
import 'booking_controller.dart';

/// Confirms before actually cancelling a booking (mockup screen C5) -
/// previously MyBookingsScreen's "Cancel" button cancelled instantly with
/// no confirmation step at all. [booking] arrives via `extra`.
class CancelBookingScreen extends ConsumerStatefulWidget {
  const CancelBookingScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends ConsumerState<CancelBookingScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myBookingsControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(myBookingsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
        return;
      }
      final wasCancelling = previous?.isLoading == true;
      if (wasCancelling && !next.isLoading && error == null) {
        AppToast.success(context, 'Booking cancelled.');
        // Pop back past the (now-stale) Booking Tracker screen straight to
        // My Bookings, rather than leaving a tracker showing a booking
        // that's since changed status underneath it.
        while (context.canPop()) {
          context.pop();
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.gutter),
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.errorContainer,
                child: Icon(Icons.priority_high, color: colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Cancel this booking?', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${widget.booking.providerBusinessName} will be notified straight away. Frequent cancellations can affect your account standing.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text('Reason · optional', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _reasonController,
                enabled: !isLoading,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(hintText: 'Tell the provider why...'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                onPressed: isLoading
                    ? null
                    : () => ref.read(myBookingsControllerProvider.notifier).cancel(
                          widget.booking.id,
                          reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
                        ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Yes, cancel booking'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: isLoading ? null : () => context.pop(),
                child: const Text('Keep it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
