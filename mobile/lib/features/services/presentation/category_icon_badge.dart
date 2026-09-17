import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
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
    final imageUrl = category.imageUrl;
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: Image.network(
          ApiClient.resolveMediaUrl(imageUrl),
          fit: BoxFit.cover,
          // A broken/unreachable upload falls back to the same default
          // icon a category with no upload at all would show, rather than
          // Flutter's own broken-image glyph - see this class's own doc
          // comment on why that fallback has to always be available.
          errorBuilder: (context, error, stackTrace) => _DefaultIcon(category: category, iconSize: iconSize),
        ),
      );
    }
    return _DefaultIcon(category: category, iconSize: iconSize);
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon({required this.category, required this.iconSize});

  final Category category;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.name);
    final color = CategoryIconBadge._legibleOn(style.color, Theme.of(context).brightness);

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
