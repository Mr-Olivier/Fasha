import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme definitions for the whole app - the "Kigali Green" design
/// system from the project's shared design spec.
///
/// Section 15 of the README requires light/dark/system theming, and says
/// screens should never set colours directly on individual widgets. This
/// class is the *only* place that should define colours/typography/shape -
/// every screen just reads them back via `Theme.of(context)`.
class AppTheme {
  AppTheme._(); // Not meant to be instantiated - only static members below.

  // --- Exact tokens from the "Kigali Green" palette spec. Every other
  // Material 3 colour role
  // (onPrimary, secondaryContainer, ...) not named there is DERIVED below
  // via ColorScheme.fromSeed rather than hand-picked - that's what keeps
  // roles we weren't given a spec for still looking deliberately chosen
  // instead of arbitrary, and keeps contrast accessible. ---
  static const _primary = Color(0xFF0F766E);
  static const _primaryContainer = Color(0xFFD8F0EC);
  static const _secondary = Color(0xFFD97706);
  static const _tertiary = Color(0xFF10B981);
  static const _surfaceLight = Color(0xFFFAFAF9);
  static const _surfaceVariantLight = Color(0xFFEEF2F1);
  static const _outlineLight = Color(0xFFE2E5E3);
  static const _onSurfaceLight = Color(0xFF0F172A);
  static const _onSurfaceVariantLight = Color(0xFF64748B);
  static const _error = Color(0xFFDC2626);

  // Dark scheme - pinned outright rather than derived via ColorScheme.fromSeed,
  // and built on the "Neutral #0F172A" token rather than a green-black tint,
  // so surfaces read as a clean charcoal (closer to how Instagram's dark
  // theme stays neutral) instead of murky/off-colour.
  static const _primaryDarkScheme = Color(0xFF34D399);
  static const _primaryContainerDark = Color(0xFF124E42);
  static const _tertiaryDark = Color(0xFF34D399);
  static const _surfaceDark = Color(0xFF0B1220);
  static const _surfaceContainerDark = Color(0xFF141B2D);
  static const _surfaceContainerHighestDark = Color(0xFF1C2537);
  static const _outlineDark = Color(0xFF2A3347);
  static const _onSurfaceDark = Color(0xFFF1F5F9);
  static const _onSurfaceVariantDark = Color(0xFF94A3B8);

  static ThemeData get light => _buildTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primary,
          primaryContainer: _primaryContainer,
          onPrimaryContainer: _onSurfaceLight,
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
          onSecondary: Colors.white,
          secondaryContainer: Color.lerp(_secondary, Colors.white, 0.85),
          onSecondaryContainer: _onSurfaceLight,
          tertiary: _tertiary,
          onTertiary: Colors.white,
          tertiaryContainer: Color.lerp(_tertiary, Colors.white, 0.85),
          onTertiaryContainer: _onSurfaceLight,
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
          onPrimary: const Color(0xFF063B33),
          primaryContainer: _primaryContainerDark,
          onPrimaryContainer: _onSurfaceDark,
          // Amber has no legibility problem on a dark background, unlike
          // primary, so it's pinned close to its light-mode value in both
          // schemes (this was a real bug during visual QA: leaving it
          // unpinned meant the "pending" status badge silently stopped
          // being amber in dark mode, using a green-tinted colour instead).
          secondary: const Color(0xFFF59E0B),
          onSecondary: const Color(0xFF3D2600),
          secondaryContainer: const Color(0xFF4A2E06),
          onSecondaryContainer: const Color(0xFFFBBF24),
          tertiary: _tertiaryDark,
          onTertiary: const Color(0xFF063B33),
          tertiaryContainer: const Color(0xFF0F3D2E),
          onTertiaryContainer: _tertiaryDark,
          surface: _surfaceDark,
          surfaceContainer: _surfaceContainerDark,
          surfaceContainerHighest: _surfaceContainerHighestDark,
          outline: _outlineDark,
          onSurface: _onSurfaceDark,
          onSurfaceVariant: _onSurfaceVariantDark,
          error: const Color(0xFFF87171),
        ),
      );

  static ThemeData _buildTheme({required ColorScheme colorScheme}) {
    final materialBase = ThemeData(brightness: colorScheme.brightness).textTheme;
    // Headline/title/label roles use Plus Jakarta Sans (the display face);
    // body roles use Inter (the reading face) - that's the split shown in
    // the design system's type-scale reference, not a single font for
    // everything.
    final displayTextTheme = GoogleFonts.plusJakartaSansTextTheme(materialBase);
    final bodyTextTheme = GoogleFonts.interTextTheme(materialBase);

    // The design spec only names a handful of type sizes (display/title/body/
    // label) - we map those onto the closest matching Material 3 text roles
    // rather than inventing a parallel type-scale.
    final textTheme = displayTextTheme.copyWith(
      headlineMedium: displayTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
      headlineSmall: displayTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
      titleLarge: displayTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleMedium: displayTextTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleSmall: displayTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      bodyLarge: bodyTextTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: bodyTextTheme.bodyMedium?.copyWith(fontSize: 13, color: colorScheme.onSurface),
      bodySmall: bodyTextTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: displayTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: displayTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: displayTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );

    final fieldBorderRadius = BorderRadius.circular(AppRadii.field);
    // A softly elevated card tone, one step up from the scaffold background -
    // the layering that makes a dark theme read as deliberate surfaces
    // stacked on each other (Instagram/most native dark UIs) rather than
    // everything flattening into the same near-black.
    final cardSurface = colorScheme.brightness == Brightness.dark ? colorScheme.surfaceContainer : colorScheme.surface;

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
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
        labelStyle: textTheme.labelLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, space: 1, thickness: 1),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.onPrimary : colorScheme.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : colorScheme.outline,
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
