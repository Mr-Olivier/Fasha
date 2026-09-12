import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import 'booking_controller.dart';
import 'request_card.dart';

/// A provider's incoming service requests, most recent first - the "see
/// all" overflow behind ProviderDashboardScreen's own request list (D1),
/// sharing the same RequestCard so the two never render a booking
/// differently. Each card's action button depends on the booking's current
/// status - see BookingStatus's doc comment for the full lifecycle this
/// follows.
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
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return RequestCard(booking: booking, onTap: () => context.push('/request-detail', extra: booking));
              },
            ),
          );
        },
      ),
    );
  }
}
