import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/call_contact_row.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'booking_status_chip.dart';

/// The customer's own bookings, most recent first (see
/// BookingRepository.listForCustomer). Only a REQUESTED or ACCEPTED
/// booking can still be cancelled - see BookingService.cancel on the
/// backend for why IN_PROGRESS and later can't.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(myBookingsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load your bookings.')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No bookings yet - browse a category from Home to request a service.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myBookingsControllerProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  bool get _canCancel => booking.status == BookingStatus.requested || booking.status == BookingStatus.accepted;

  bool get _canReview => booking.status == BookingStatus.completed;

  /// The provider only becomes reachable once they've actually accepted -
  /// showing their number while still just REQUESTED would be pointless
  /// (and REJECTED/CANCELLED have nothing left to coordinate).
  bool get _canCallProvider => switch (booking.status) {
        BookingStatus.accepted || BookingStatus.inProgress || BookingStatus.completed || BookingStatus.reviewed => true,
        _ => false,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(booking.serviceName, style: textTheme.titleMedium)),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('with ${booking.providerBusinessName}', style: textTheme.bodyMedium),
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(booking.note!, style: textTheme.bodySmall),
            ],
            const SizedBox(height: 4),
            Text('RWF ${booking.servicePrice.toStringAsFixed(0)}', style: textTheme.bodySmall),
            if (_canCallProvider && booking.providerPhone != null) ...[
              const SizedBox(height: 4),
              CallContactRow(name: booking.providerBusinessName, phone: booking.providerPhone!),
            ],
            if (_canCancel) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref.read(myBookingsControllerProvider.notifier).cancel(booking.id),
                  child: const Text('Cancel'),
                ),
              ),
            ],
            if (_canReview) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => context.push('/write-review', extra: booking),
                  child: const Text('Leave a review'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
