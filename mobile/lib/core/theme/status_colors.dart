import 'package:flutter/material.dart';

/// Maps a semantic outcome onto one of the app's own theme colours, instead
/// of Flutter's generic named colours (Colors.orange/green/red) which don't
/// relate to the brand palette at all and don't adapt to dark mode.
///
/// Currently used for provider verification status (pending/approved/
/// rejected); the same three tones will apply to booking status chips once
/// that feature (Feature 6/7) exists - REQUESTED/pending, ACCEPTED &
/// COMPLETED/positive, CANCELLED & REJECTED/negative.
class StatusColors {
  StatusColors._();

  static Color pending(BuildContext context) => Theme.of(context).colorScheme.secondary;

  static Color positive(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color negative(BuildContext context) => Theme.of(context).colorScheme.error;
}
