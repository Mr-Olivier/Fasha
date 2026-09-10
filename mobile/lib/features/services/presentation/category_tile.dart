import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/category.dart';
import 'category_icon_badge.dart';

/// One cell of Home's category grid: a square icon badge (see
/// [CategoryIconBadge]) with the category's name underneath - the same
/// tile shape (`aspect-ratio:1`, `border-radius:16`) as the "Categories"
/// section of the project's own design reference
/// (`fasha-app-final-ui.html`, screen B1), just with a real icon in the
/// badge instead of that mockup's two-letter placeholder text.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(aspectRatio: 1, child: CategoryIconBadge(category: category)),
          const SizedBox(height: 6),
          Text(
            category.name.split(RegExp(r'[\s&]+')).first,
            style: textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
