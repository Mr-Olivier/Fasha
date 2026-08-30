import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../domain/verification_status.dart';

/// Public (not the screen-private widget it started as) so both
/// ProviderProfileScreen and HomeScreen's provider dashboard can show the
/// same badge without duplicating it.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      VerificationStatus.pending => ('Pending review', StatusColors.pending(context)),
      VerificationStatus.approved => ('Approved', StatusColors.positive(context)),
      VerificationStatus.rejected => ('Rejected', StatusColors.negative(context)),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        backgroundColor: color.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: color),
        side: BorderSide(color: color),
      ),
    );
  }
}
