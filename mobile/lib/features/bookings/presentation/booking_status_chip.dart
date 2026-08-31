import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../domain/booking_status.dart';

/// Same visual language as VerificationBadge (features/providers) - see
/// StatusColors's own doc comment for the REQUESTED/pending,
/// ACCEPTED+IN_PROGRESS+COMPLETED/positive, CANCELLED+REJECTED/negative
/// mapping this was already planned around.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.requested => ('Requested', StatusColors.pending(context)),
      BookingStatus.accepted => ('Accepted', StatusColors.positive(context)),
      BookingStatus.inProgress => ('In progress', StatusColors.positive(context)),
      BookingStatus.completed => ('Completed', StatusColors.positive(context)),
      BookingStatus.rejected => ('Rejected', StatusColors.negative(context)),
      BookingStatus.cancelled => ('Cancelled', StatusColors.negative(context)),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
