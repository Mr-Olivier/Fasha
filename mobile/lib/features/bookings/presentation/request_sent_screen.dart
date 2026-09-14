import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/booking.dart';
import '../domain/time_window.dart';
import 'booking_status_chip.dart';

/// Confirmation shown right after RequestBookingScreen submits
/// successfully (mockup screen C1) - replaces the previous
/// toast-then-redirect-to-bookings behaviour with an actual "what happens
/// next" screen.
class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.check, size: 40, color: colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text('Request sent', style: textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${booking.providerBusinessName} has 24 hours to accept. You\'ll get a notification the moment they respond.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _Row(label: 'Service', value: booking.serviceName),
                      const Divider(height: AppSpacing.gutter),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: textTheme.bodyMedium),
                          BookingStatusChip(status: booking.status),
                        ],
                      ),
                      if (booking.requestedDate != null || booking.timeWindow != null) ...[
                        const Divider(height: AppSpacing.gutter),
                        _Row(
                          label: 'When',
                          value: [
                            if (booking.requestedDate != null)
                              '${booking.requestedDate!.year}-${booking.requestedDate!.month.toString().padLeft(2, '0')}-${booking.requestedDate!.day.toString().padLeft(2, '0')}',
                            if (booking.timeWindow != null) booking.timeWindow!.label,
                          ].join(' · '),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.pushReplacement('/booking-tracker', extra: booking),
                child: const Text('Track this booking'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}
