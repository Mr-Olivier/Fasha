import 'package:flutter/material.dart';

import '../domain/booking_status.dart';

/// A thin "step X of Y" bar along [bookingHappyPathStages] - the same
/// stage list BookingTrackerScreen's own timeline walks, just compressed to
/// one line for a card (MyBookingsScreen) or a status banner
/// (ActiveJobScreen) instead of a full vertical timeline. Renders nothing
/// for a status that's branched off the happy path (REJECTED/CANCELLED) -
/// see [bookingHappyPathStages]'s own doc comment for why those don't get
/// a "step X of Y" reading at all.
class BookingProgressBar extends StatelessWidget {
  const BookingProgressBar({super.key, required this.status, this.trackColor, this.valueColor});

  final BookingStatus status;

  /// Defaults to the theme's surfaceContainerHighest/primary - overridable
  /// for a spot (like ActiveJobScreen's coloured banner) where the surrounding
  /// background isn't the plain scaffold surface those defaults assume.
  final Color? trackColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stepIndex = bookingHappyPathStages.indexOf(status);
    if (stepIndex == -1) return const SizedBox.shrink();
    final total = bookingHappyPathStages.length;
    final fraction = (stepIndex + 1) / total;
    final color = valueColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: trackColor ?? colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text('Step ${stepIndex + 1} of $total', style: textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
