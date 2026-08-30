import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/category.dart';

/// The two-letter tile from the design (EL/PL/ME/CL/...) - derived from
/// the category's own name rather than a hardcoded lookup table, so it
/// keeps working for every category an admin adds later (Feature 9),
/// not just the 8 seeded ones we know about today.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  String get _initials {
    final firstWord = category.name.trim().split(RegExp(r'[\s&]+')).first;
    return firstWord.length >= 2 ? firstWord.substring(0, 2).toUpperCase() : firstWord.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              child: Text(_initials, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              category.name.split(' ').first,
              style: textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
