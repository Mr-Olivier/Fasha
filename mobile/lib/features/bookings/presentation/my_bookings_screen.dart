import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/call_contact_row.dart';
import '../../../core/widgets/chat_entry_row.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'booking_status_chip.dart';

const _activeStatuses = {BookingStatus.requested, BookingStatus.accepted, BookingStatus.inProgress};

/// The customer's own bookings, split into Active/Past tabs (mockup screen
/// C2) - most recent first within each (see BookingRepository.listForCustomer).
/// Tapping a card opens the Booking Tracker (C3); only a REQUESTED or
/// ACCEPTED booking shows a "Cancel" action here - see BookingService.cancel
/// on the backend for why IN_PROGRESS and later can't be cancelled.
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          bottom: state.valueOrNull != null
              ? TabBar(
                  tabs: [
                    Tab(text: 'Active · ${state.value!.where((b) => _activeStatuses.contains(b.status)).length}'),
                    Tab(text: 'Past · ${state.value!.where((b) => !_activeStatuses.contains(b.status)).length}'),
                  ],
                )
              : null,
        ),
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
            final active = bookings.where((b) => _activeStatuses.contains(b.status)).toList();
            final past = bookings.where((b) => !_activeStatuses.contains(b.status)).toList();
            return TabBarView(
              children: [
                _BookingList(bookings: active, emptyMessage: 'Nothing active right now.'),
                _BookingList(bookings: past, emptyMessage: 'No past bookings yet.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.bookings, required this.emptyMessage});

  final List<Booking> bookings;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myBookingsControllerProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => BookingCard(booking: bookings[index]),
      ),
    );
  }
}

/// One booking's summary card - shared by MyBookingsScreen's list and (in
/// future) any other screen that wants the same at-a-glance summary.
/// Extracted from a screen-private class so it isn't duplicated.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/booking-tracker', extra: booking),
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
              if (_canCallProvider) ...[
                const SizedBox(height: 4),
                ChatEntryRow(bookingId: booking.id, name: booking.providerBusinessName),
              ],
              if (_canCancel) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/cancel-booking', extra: booking),
                    child: const Text('Cancel request'),
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
      ),
    );
  }
}
