import 'package:flutter/material.dart';

/// A read-only row of 5 stars (full/half/empty) for [rating] - the amber
/// secondary color by default, matching the design system's accent.
/// For picking a rating (not just displaying one), see WriteReviewScreen's
/// own tappable star row - a different widget, since input needs
/// StatefulWidget/callback wiring this display-only one doesn't.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16, this.color});

  final double rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Theme.of(context).colorScheme.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final threshold = index + 1;
        final icon = rating >= threshold
            ? Icons.star
            : (rating >= threshold - 0.5 ? Icons.star_half : Icons.star_border);
        return Icon(icon, size: size, color: starColor);
      }),
    );
  }
}
