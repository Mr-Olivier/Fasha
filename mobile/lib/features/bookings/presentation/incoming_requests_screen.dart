import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/call_contact_row.dart';
import '../../../core/widgets/chat_entry_row.dart';
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
        AppToast.apiError(context, error);
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

  /// Same reasoning as MyBookingsScreen's _canCallProvider, mirrored for
  /// the provider's side: the customer only becomes reachable once
  /// there's actually a job to coordinate.
  bool get _canCallCustomer => switch (booking.status) {
        BookingStatus.accepted || BookingStatus.inProgress || BookingStatus.completed || BookingStatus.reviewed => true,
        _ => false,
      };

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
            if (_canCallCustomer && booking.customerPhone != null) ...[
              const SizedBox(height: 4),
              CallContactRow(name: booking.customerName, phone: booking.customerPhone!),
            ],
            if (_canCallCustomer) ...[
              const SizedBox(height: 4),
              ChatEntryRow(bookingId: booking.id, name: booking.customerName),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              // AppTheme's FilledButtonThemeData sets minimumSize to
              // Size.fromHeight(52) - Size.fromHeight means "infinite
              // width, fixed height", which is exactly what every OTHER
              // FilledButton in the app wants (a full-width primary action
              // in a stretched Column). Inside a Row here instead, that
              // infinite minWidth silently breaks layout - the button
              // never actually appears. compactButtonStyle overrides it
              // back to a normal, content-sized button for this one place.
              child: switch (booking.status) {
                BookingStatus.requested => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () => notifier.reject(booking.id), child: const Text('Reject')),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        style: _compactButtonStyle,
                        onPressed: () => notifier.accept(booking.id),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                BookingStatus.accepted => FilledButton(
                    style: _compactButtonStyle,
                    onPressed: () => notifier.start(booking.id),
                    child: const Text('Start job'),
                  ),
                BookingStatus.inProgress => FilledButton(
                    style: _compactButtonStyle,
                    onPressed: () => notifier.complete(booking.id),
                    child: const Text('Mark complete'),
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// See the doc comment where this is used - overrides AppTheme's
/// full-width FilledButton default back to a normal, content-sized button.
final ButtonStyle _compactButtonStyle = FilledButton.styleFrom(minimumSize: const Size(64, 36));
