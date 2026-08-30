import 'package:flutter/material.dart';

import '../../../core/widgets/app_logo.dart';

/// Shown while AuthController restores a previous session from secure
/// storage (see app_router.dart's redirect logic) - this is a real loading
/// state tied to that async check, not just a fixed-duration splash, so it
/// only ever appears for as long as the restore actually takes.
///
/// The design reference's splash is the first slide of a swipeable
/// onboarding carousel (dot indicators, multiple slides) - we only build
/// this one static slide, since there's no onboarding content behind the
/// other dots yet.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(),
            const SizedBox(height: 24),
            Text(
              'KaziLink',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const Text(
              'RWANDA',
              style: TextStyle(color: Colors.white70, letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('Trusted local services, one tap away', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
