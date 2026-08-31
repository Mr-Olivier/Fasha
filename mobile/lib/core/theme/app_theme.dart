import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme definitions for the whole app - the "Kigali Green" design
/// system from the project's shared design reference (see project memory
/// for the canvas link and full token list).
///
/// Section 15 of the README requires light/dark/system theming, and says
/// screens should never set colours directly on individual widgets. This
/// class is the *only* place that should define colours/typography/shape -
/// every screen just reads them back via `Theme.of(context)`.
class AppTheme {
  AppTheme._(); // Not meant to be instantiated - only static members below.

  // --- Exact tokens from the design spec (fasha-app-final-ui.html's
  // "DESIGN TOKENS" section - the full 38-screen reference, light + dark). ---
  // Every other Material 3 colour role (onPrimary, tertiary, ...) not named
  // there is DERIVED below via ColorScheme.fromSeed rather than hand-picked -
  // that's what keeps roles we weren't given a spec for still looking
  // deliberately chosen instead of arbitrary, and keeps contrast accessible.
  static const _primary = Color(0xFF0B6B4F);
  static const _primaryContainer = Color(0xFFDCEFE7);
  static const _secondary = Color(0xFFE8A33D);
  static const _surfaceLight = Color(0xFFFBFAF6);
  static const _surfaceVariantLight = Color(0xFFEFEDE6);
  static const _outlineLight = Color(0xFFE7E4DB);
  static const _onSurfaceLight = Color(0xFF132420);
  static const _onSurfaceVariantLight = Color(0xFF6E7A73);
  static const _error = Color(0xFFB3261E);

  // Dark scheme - pinned outright rather than derived via ColorScheme.fromSeed,
  // since the design spec gives every one of these roles an exact value.
  static const _primaryDarkScheme = Color(0xFF4EAE8B);
  static const _primaryContainerDark = Color(0xFF1B3A2E);
  static const _surfaceDark = Color(0xFF0F1714);
  static const _outlineDark = Color(0xFF24332C);
  static const _onSurfaceDark = Color(0xFFEDF2EF);
  static const _onSurfaceVariantDark = Color(0xFF8A9791);

  static ThemeData get light => _buildTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primary,
          primaryContainer: _primaryContainer,
          secondary: _secondary,
          // fromSeed only knows how to derive a secondary tonal palette FROM
          // the primary seed - it has no idea we're about to override
          // secondary with an unrelated amber, so its auto-generated
          // onSecondary/secondaryContainer wouldn't actually contrast or
          // harmonize with amber. We derive those two ourselves instead:
          // a light tint of the amber itself for the container (this also
          // happens to land close to the "pending" chip tone from the
          // design's status-colour swatches), and the same dark ink used
          // for onSurface everywhere else - one ink colour for all text
          // reads as more deliberate than a separate near-black per accent.
          onSecondary: _onSurfaceLight,
          secondaryContainer: Color.lerp(_secondary, Colors.white, 0.85),
          onSecondaryContainer: _onSurfaceLight,
          surface: _surfaceLight,
          surfaceContainerHighest: _surfaceVariantLight,
          outline: _outlineLight,
          onSurface: _onSurfaceLight,
          onSurfaceVariant: _onSurfaceVariantLight,
          error: _error,
        ),
      );

  static ThemeData get dark => _buildTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: _primaryDarkScheme,
          primaryContainer: _primaryContainerDark,
          onPrimaryContainer: _onSurfaceDark,
          // Amber has no legibility problem on a dark background, unlike
          // primary, so it's pinned to the same value in both schemes (this
          // was a real bug during visual QA: leaving it unpinned meant the
          // "pending" status badge silently stopped being amber in dark
          // mode, using a green-tinted colour instead).
          secondary: _secondary,
          onSecondary: _onSurfaceLight,
          secondaryContainer: Color.lerp(_secondary, Colors.black, 0.55),
          onSecondaryContainer: _secondary,
          surface: _surfaceDark,
          surfaceContainerHighest: const Color(0xFF18241F),
          outline: _outlineDark,
          onSurface: _onSurfaceDark,
          onSurfaceVariant: _onSurfaceVariantDark,
        ),
      );

  static ThemeData _buildTheme({required ColorScheme colorScheme}) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData(brightness: colorScheme.brightness).textTheme);

    // The design spec only names a handful of type sizes (display/title/body/
    // label) - we map those onto the closest matching Material 3 text roles
    // rather than inventing a parallel type-scale.
    final textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13, color: colorScheme.onSurface),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );

    final fieldBorderRadius = BorderRadius.circular(AppRadii.field);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(borderRadius: fieldBorderRadius, borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder:
            OutlineInputBorder(borderRadius: fieldBorderRadius, borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder:
            OutlineInputBorder(borderRadius: fieldBorderRadius, borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: fieldBorderRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: fieldBorderRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
        labelStyle: textTheme.labelLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
      ),
    );
  }
}

/// Corner radii from the design spec: "14 chips · 16 fields · 20 cards · 40 sheet".
class AppRadii {
  AppRadii._();

  static const double chip = 14;
  static const double field = 16;
  static const double card = 20;
  static const double sheet = 40;
}

/// Spacing scale from the design spec: "4 · 8 · 12 · 22 gutters".
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double gutter = 22;
}
