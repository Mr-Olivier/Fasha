import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'booking_status_chip.dart';

/// A provider's incoming service requests, most recent first. Each card's
/// action button depends on the booking's current status - see
/// BookingStatus's doc comment for the full lifecycle this follows.
class IncomingRequestsScreen extends ConsumerWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomingRequestsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(incomingRequestsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        final message = error is ApiException ? error.message : 'Something went wrong.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming requests')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load your requests.')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No requests yet - they\'ll show up here once a customer books one of your services.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(incomingRequestsControllerProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _RequestCard(booking: bookings[index]),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(incomingRequestsControllerProvider.notifier);

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
            Text('from ${booking.customerName}', style: textTheme.bodyMedium),
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(booking.note!, style: textTheme.bodySmall),
            ],
            const SizedBox(height: 4),
            Text('RWF ${booking.servicePrice.toStringAsFixed(0)}', style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: switch (booking.status) {
                BookingStatus.requested => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () => notifier.reject(booking.id), child: const Text('Reject')),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(onPressed: () => notifier.accept(booking.id), child: const Text('Accept')),
                    ],
                  ),
                BookingStatus.accepted =>
                  FilledButton(onPressed: () => notifier.start(booking.id), child: const Text('Start job')),
                BookingStatus.inProgress =>
                  FilledButton(onPressed: () => notifier.complete(booking.id), child: const Text('Mark complete')),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
