import 'package:flutter/material.dart';

/// The "K" mark from the design system - an amber rounded-square tile with
/// a bold white "K". Currently only used on the splash screen, but kept as
/// its own small widget since a logo mark tends to get reused (an app bar,
/// an about screen, ...) as an app grows.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        'K',
        style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
