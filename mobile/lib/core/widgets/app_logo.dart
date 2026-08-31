import 'package:flutter/material.dart';

/// The Fasha app mark (assets/images/logo.png) - a solid rounded-square
/// tile, same shape language as a home-screen app icon. Currently only
/// used on the splash screen, but kept as its own small widget since a
/// logo mark tends to get reused (an app bar, an about screen, ...) as an
/// app grows.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
