import 'package:flutter/material.dart';

/// Central theme definitions for the whole app.
///
/// Section 15 of the README requires light/dark/system theming, and says
/// screens should never set colours directly on individual widgets. This
/// class is the *only* place that should define colours/typography - every
/// screen just reads them back via `Theme.of(context)`.
class AppTheme {
  AppTheme._(); // Not meant to be instantiated - only static members below.

  /// The single brand colour every other colour in the app is derived from.
  /// Material 3's `ColorScheme.fromSeed` generates a full, accessible colour
  /// palette (primary/secondary/surface/error/...) from just this one seed.
  static const _seedColor = Color(0xFF2E7D32); // a Rwandan-green shade

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}
