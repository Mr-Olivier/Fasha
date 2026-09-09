import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_logo.dart';

/// The logo + title + subtitle block shown at the top of every auth screen
/// (login, register, forgot/reset password, verify email) - pulled into one
/// widget so all five stay visually consistent instead of each screen
/// hand-rolling its own heading.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle, this.logoSize = 56});

  final String title;
  final String subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
