import 'package:flutter/material.dart';

import '../domain/category.dart';
import 'category_style.dart';

/// A "bubble" tile for the Home category rail: a circular icon avatar in
/// the category's own accent colour, name underneath. This is the same
/// visual pattern Instagram uses for Stories and most delivery/marketplace
/// apps (Jiji, Urban Company, Glovo) use for their category rail - a row of
/// coloured circles is instantly scannable in a way a row of plain text
/// labels isn't, which matters here since Home shows every category at
/// once. See [CategoryStyle] for the icon/colour lookup.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  static const double _bubbleSize = 64;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.name);
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_bubbleSize / 2 + 6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _bubbleSize,
                height: _bubbleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color.withValues(alpha: 0.14),
                  border: Border.all(color: style.color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(style.icon, color: style.color, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                style: textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
