import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/call_contact_row.dart';
import '../../chat/presentation/chat_screen.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import '../domain/booking_status_history_entry.dart';
import '../domain/time_window.dart';
import 'booking_status_chip.dart';

/// The status timeline for one booking (mockup screen C3), reached from
/// "Track this booking" (Request Sent) or tapping a card on My Bookings.
/// [booking] arrives via `extra` - same convention as every other
/// detail-screen route in this app (RequestDetailScreen, ActiveJobScreen).
/// The timeline itself is driven by [Booking.statusHistory] (see
/// V30__create_booking_status_history.sql on the backend for why that
/// exists) rather than guessing timestamps from a single updatedAt.
class BookingTrackerScreen extends StatelessWidget {
  const BookingTrackerScreen({super.key, required this.booking});

  final Booking booking;

  bool get _isTerminalFailure => booking.status == BookingStatus.rejected || booking.status == BookingStatus.cancelled;

  bool get _canCancel => booking.status == BookingStatus.requested || booking.status == BookingStatus.accepted;

  /// Same "who's reachable once" rule MyBookingsScreen's _canCallProvider
  /// uses - accepted onward, nothing left to coordinate once
  /// rejected/cancelled.
  bool get _canContact => switch (booking.status) {
        BookingStatus.accepted || BookingStatus.inProgress || BookingStatus.completed || BookingStatus.reviewed => true,
        _ => false,
      };

  String _statusHeadline() => switch (booking.status) {
        BookingStatus.requested => 'Waiting for ${booking.providerBusinessName} to respond',
        BookingStatus.accepted => '${booking.providerBusinessName} accepted your request',
        BookingStatus.inProgress => '${booking.providerBusinessName} is working on your job now',
        BookingStatus.completed => 'Job completed - leave a review when you\'re ready',
        BookingStatus.reviewed => 'Job completed and reviewed',
        BookingStatus.rejected => '${booking.providerBusinessName} couldn\'t take this request',
        BookingStatus.cancelled => 'You cancelled this request',
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _isTerminalFailure ? colorScheme.error : colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(booking.serviceName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'CURRENT STATUS',
                        style: textTheme.labelSmall?.copyWith(color: statusColor, letterSpacing: 1.1),
                      ),
                      const Spacer(),
                      BookingStatusChip(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_statusHeadline(), style: textTheme.titleMedium),
                  if (_canContact) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(booking.providerBusinessName.isNotEmpty ? booking.providerBusinessName[0] : '?'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.providerBusinessName, style: textTheme.titleMedium),
                              if (booking.providerPhone != null)
                                CallContactRow(name: booking.providerBusinessName, phone: booking.providerPhone!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Text('Timeline', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _Timeline(booking: booking),
          const SizedBox(height: AppSpacing.gutter),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (booking.requestedDate != null || booking.timeWindow != null) ...[
                    _DetailRow(
                      label: booking.requestedDate != null ? 'Requested date' : 'Time window',
                      // Date and time window can each be set independently
                      // (the Request Service form lets a customer pick just
                      // one) - show whichever combination exists rather
                      // than nesting the window's display under a date
                      // that might not be there.
                      value: [
                        if (booking.requestedDate != null)
                          '${booking.requestedDate!.year}-${booking.requestedDate!.month.toString().padLeft(2, '0')}-${booking.requestedDate!.day.toString().padLeft(2, '0')}',
                        if (booking.timeWindow != null) booking.timeWindow!.label,
                      ].join(' · '),
                    ),
                    const Divider(height: AppSpacing.gutter),
                  ],
                  if (booking.address != null && booking.address!.isNotEmpty) ...[
                    _DetailRow(label: 'Address', value: booking.address!),
                    const Divider(height: AppSpacing.gutter),
                  ],
                  _DetailRow(label: 'Agreed price', value: 'RWF ${booking.servicePrice.toStringAsFixed(0)}'),
                  if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ...[
                    const Divider(height: AppSpacing.gutter),
                    _DetailRow(label: 'Cancellation reason', value: booking.cancellationReason!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              if (_canCancel)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                    onPressed: () => context.push('/cancel-booking', extra: booking),
                    child: const Text('Cancel booking'),
                  ),
                ),
              if (_canCancel && _canContact) const SizedBox(width: AppSpacing.sm),
              if (_canContact)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push(
                      '/chat',
                      extra: ChatScreenArgs(bookingId: booking.id, otherPartyName: booking.providerBusinessName),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                  ),
                ),
            ],
          ),
          if (booking.status == BookingStatus.completed) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => context.push('/write-review', extra: booking),
              child: const Text('Leave a review'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The standard happy-path stages every booking passes through in order.
/// REJECTED/CANCELLED aren't in this list - they're terminal branches off
/// it, rendered separately (see _Timeline below) rather than pretending
/// the booking is still progressing toward COMPLETED.
const _happyPathStages = [
  BookingStatus.requested,
  BookingStatus.accepted,
  BookingStatus.inProgress,
  BookingStatus.completed,
  BookingStatus.reviewed,
];

class _Timeline extends StatelessWidget {
  const _Timeline({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final history = {for (final entry in booking.statusHistory) entry.status: entry};
    final isTerminalFailure = booking.status == BookingStatus.rejected || booking.status == BookingStatus.cancelled;

    // On a rejected/cancelled booking, show exactly what happened (from
    // statusHistory) rather than the fixed happy-path stage list - a
    // cancelled booking never reaches ACCEPTED/COMPLETED, so listing those
    // as "pending" would be misleading.
    final stages = isTerminalFailure
        ? booking.statusHistory.map((e) => e.status).toList()
        : _happyPathStages;

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _TimelineTile(
            status: stages[i],
            entry: history[stages[i]],
            isLast: i == stages.length - 1,
            isFailure: isTerminalFailure,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.status, required this.entry, required this.isLast, required this.isFailure});

  final BookingStatus status;
  final BookingStatusHistoryEntry? entry;
  final bool isLast;
  final bool isFailure;

  String get _label => switch (status) {
        BookingStatus.requested => 'Request sent',
        BookingStatus.accepted => 'Provider accepted',
        BookingStatus.inProgress => 'Job started',
        BookingStatus.completed => 'Job completed',
        BookingStatus.reviewed => 'Reviewed',
        BookingStatus.rejected => 'Request declined',
        BookingStatus.cancelled => 'Booking cancelled',
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final reached = entry != null;
    final dotColor = !reached
        ? colorScheme.outline
        : isFailure
            ? colorScheme.error
            : colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: colorScheme.outline)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: textTheme.titleMedium?.copyWith(color: reached ? null : colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                  if (entry != null)
                    Text(
                      entry!.changedAt.toLocal().toString().substring(0, 16),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
        const Spacer(),
        Flexible(
          child: Text(value, style: textTheme.titleMedium, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
