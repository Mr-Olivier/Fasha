import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/category.dart';
import 'category_style.dart';

/// The rounded-square, tinted icon badge used for a category everywhere it
/// appears - Home's category grid, the "browse all categories" list, and
/// (via the same 16px radius as `AppRadii.field`) visually related to every
/// other rounded-square surface in the app, not a one-off shape.
///
/// A single shared widget so the "which colour reads legibly in dark mode"
/// logic (see [_legibleOn]) only has to live in one place.
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({super.key, required this.category, this.iconSize = 26});

  final Category category;
  final double iconSize;

  /// CategoryStyle's hexes were chosen to read well on the light theme's
  /// near-white surface - a few (navy, dark brown) are too dark to read on
  /// the dark theme's near-black surface instead (see AppTheme's
  /// `_surfaceDark`). Rather than hand-picking a second hex per category for
  /// dark mode, lighten any colour that's too dark until it clears a
  /// legible luminance floor, and leave already-bright colours untouched.
  static Color _legibleOn(Color color, Brightness brightness) {
    if (brightness == Brightness.light) return color;
    var lightened = color;
    while (lightened.computeLuminance() < 0.4) {
      lightened = Color.lerp(lightened, Colors.white, 0.15)!;
    }
    return lightened;
  }

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.name);
    final color = _legibleOn(style.color, Theme.of(context).brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(child: Icon(style.icon, color: color, size: iconSize)),
    );
  }
}
