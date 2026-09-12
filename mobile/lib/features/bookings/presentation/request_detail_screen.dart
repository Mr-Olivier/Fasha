import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_controller.dart';
import 'request_card.dart';

/// How long a provider has to respond to a fresh request before D2's
/// countdown banner reads as "overdue" - a purely visual nudge (see
/// PROJECT_STATUS.md's provider-tools plan, decision #2): nothing on the
/// backend actually expires or auto-rejects the request when this runs out.
const _responseWindow = Duration(hours: 24);

/// D2 - a single request's full detail, reached by tapping a RequestCard.
/// Shown via `extra` (see app_router.dart), not re-fetched by id - the
/// caller already has the full Booking object in hand.
class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.booking.status == BookingStatus.requested) {
      _updateRemaining();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
    }
  }

  void _updateRemaining() {
    final deadline = widget.booking.createdAt.add(_responseWindow);
    final remaining = deadline.difference(DateTime.now());
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _remainingLabel {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(incomingRequestsControllerProvider.notifier);
    final isOverdue = _remaining == Duration.zero;

    return Scaffold(
      appBar: AppBar(title: Text('Request #${booking.id.substring(0, 6).toUpperCase()}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (booking.status == BookingStatus.requested)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: StatusColors.pending(context).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    isOverdue ? 'RESPONSE WINDOW HAS PASSED' : 'RESPOND WITHIN $_remainingLabel',
                    style: textTheme.labelLarge?.copyWith(color: StatusColors.pending(context)),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              child: ListTile(
                title: Text(booking.customerName),
                subtitle: booking.customerPhone != null ? Text(booking.customerPhone!) : null,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _DetailRow(label: 'Service', value: booking.serviceName),
                    _DetailRow(
                      label: 'Requested',
                      value: booking.requestedDate != null
                          ? '${booking.requestedDate!.year}-${booking.requestedDate!.month.toString().padLeft(2, '0')}-${booking.requestedDate!.day.toString().padLeft(2, '0')}'
                          : 'Flexible',
                    ),
                    _DetailRow(label: 'Your price', value: 'RWF ${booking.servicePrice.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text('Job description', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(booking.note!, style: textTheme.bodyMedium),
                ),
              ),
            ],
            if (booking.status == BookingStatus.requested) ...[
              const SizedBox(height: AppSpacing.gutter),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await notifier.reject(booking.id);
                        if (context.mounted) context.pop();
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await notifier.accept(booking.id);
                        if (context.mounted) context.pop();
                      },
                      child: const Text('Accept request'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.gutter),
              RequestCard(booking: booking),
            ],
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          const Spacer(),
          Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
