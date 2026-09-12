import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/call_contact_row.dart';
import '../../../core/widgets/chat_entry_row.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'booking_status_chip.dart';

/// One incoming request/job card - shared by ProviderDashboardScreen (D1)
/// and IncomingRequestsScreen's "see all" list, so the two never drift
/// apart. [onTap] is optional so a caller that doesn't need drill-down
/// (there isn't one today, but keeps this reusable) can omit it.
class RequestCard extends ConsumerWidget {
  const RequestCard({super.key, required this.booking, this.onTap});

  final Booking booking;
  final VoidCallback? onTap;

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
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
                          style: compactButtonStyle,
                          onPressed: () => notifier.accept(booking.id),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  BookingStatus.accepted => FilledButton(
                      style: compactButtonStyle,
                      onPressed: () => notifier.start(booking.id),
                      child: const Text('Start job'),
                    ),
                  BookingStatus.inProgress => FilledButton(
                      style: compactButtonStyle,
                      onPressed: () => context.push('/active-job', extra: booking),
                      child: const Text('Continue job'),
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overrides AppTheme's full-width FilledButton default back to a normal,
/// content-sized button - needed anywhere a FilledButton sits inside a Row
/// (e.g. this card's action row) instead of a stretched Column.
final ButtonStyle compactButtonStyle = FilledButton.styleFrom(minimumSize: const Size(64, 36));
