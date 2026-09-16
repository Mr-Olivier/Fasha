import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'request_card.dart';

enum _StatusFilter { all, pending, accepted, done }

/// A provider's incoming service requests, most recent first - the "see
/// all" overflow behind ProviderDashboardScreen's own request list (D1),
/// sharing the same RequestCard so the two never render a booking
/// differently. Each card's action button depends on the booking's current
/// status - see BookingStatus's doc comment for the full lifecycle this
/// follows.
class IncomingRequestsScreen extends ConsumerStatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  ConsumerState<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

/// The neighbourhood a booking's freeform [Booking.address] was placed in -
/// customers enter it as "street, district" (see RequestBookingScreen's own
/// hint text, "e.g. KK 15 Ave, Kicukiro"), so the text after the last comma
/// is a reasonable, best-effort district label. Never invented when the
/// address doesn't look like that (no comma, or empty) - those bookings
/// just don't get a district chip, rather than showing a wrong one.
String? _districtOf(Booking booking) {
  final address = booking.address;
  if (address == null || address.trim().isEmpty) return null;
  final parts = address.split(',');
  if (parts.length < 2) return null;
  final district = parts.last.trim();
  return district.isEmpty ? null : district;
}

bool _matchesStatus(Booking booking, _StatusFilter filter) => switch (filter) {
      _StatusFilter.all => true,
      _StatusFilter.pending => booking.status == BookingStatus.requested,
      _StatusFilter.accepted => booking.status == BookingStatus.accepted || booking.status == BookingStatus.inProgress,
      _StatusFilter.done => booking.status == BookingStatus.completed || booking.status == BookingStatus.reviewed,
    };

class _IncomingRequestsScreenState extends ConsumerState<IncomingRequestsScreen> {
  String? _districtFilter;
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
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

          final districts = bookings.map(_districtOf).whereType<String>().toSet().toList()..sort();
          if (_districtFilter != null && !districts.contains(_districtFilter)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _districtFilter = null);
            });
          }

          final filtered = bookings
              .where((b) => _districtFilter == null || _districtOf(b) == _districtFilter)
              .where((b) => _matchesStatus(b, _statusFilter))
              .toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(incomingRequestsControllerProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: [
                if (districts.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All areas'),
                          selected: _districtFilter == null,
                          onSelected: (_) => setState(() => _districtFilter = null),
                        ),
                        for (final district in districts) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ChoiceChip(
                            label: Text(district),
                            selected: _districtFilter == district,
                            onSelected: (_) => setState(() => _districtFilter = district),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Row(
                  children: [
                    for (final filter in _StatusFilter.values) ...[
                      Expanded(child: _StatusTab(
                        label: switch (filter) {
                          _StatusFilter.all => 'All (${bookings.length})',
                          _StatusFilter.pending =>
                            'Pending (${bookings.where((b) => _matchesStatus(b, filter)).length})',
                          _StatusFilter.accepted =>
                            'Accepted (${bookings.where((b) => _matchesStatus(b, filter)).length})',
                          _StatusFilter.done => 'Done (${bookings.where((b) => _matchesStatus(b, filter)).length})',
                        },
                        selected: _statusFilter == filter,
                        onTap: () => setState(() => _statusFilter = filter),
                      )),
                      if (filter != _StatusFilter.values.last) const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
                    child: Text(
                      'No requests match this filter.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  )
                else
                  for (final booking in filtered) ...[
                    RequestCard(booking: booking, onTap: () => context.push('/request-detail', extra: booking)),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
