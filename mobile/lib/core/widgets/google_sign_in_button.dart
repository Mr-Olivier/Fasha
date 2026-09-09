import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A labeled divider ("or continue with") plus a "Continue with Google"
/// button - the whole block auth screens drop in below their normal
/// email/password form. One widget so the divider and button always show
/// up together, styled the same way, everywhere they're used.
class GoogleSignInSection extends StatelessWidget {
  const GoogleSignInSection({super.key, required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'or',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outline)),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleG(),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Continue with Google'),
                  ],
                ),
        ),
      ],
    );
  }
}

/// A small "G" mark - not a pixel-perfect reproduction of Google's
/// trademarked logo, just enough of a nod (Google's brand blue, on a white
/// circle) that "Continue with Google" reads as the familiar pattern users
/// already know from other apps.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w700, fontSize: 14, height: 1),
      ),
    );
  }
}
