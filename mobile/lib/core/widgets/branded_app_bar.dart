import 'package:flutter/material.dart';

import 'app_logo.dart';

/// The persistent "logo + wordmark (+ optional subtitle)" header every
/// top-level (tab-root) screen carries in the design reference - Home,
/// My Services, Reviews, Profile, and their provider/admin equivalents all
/// show the small squarish Fasha mark next to the screen's own title,
/// rather than a bare text AppBar. A dedicated PreferredSizeWidget (not a
/// helper that returns an AppBar) so it drops straight into any Scaffold's
/// `appBar:` slot exactly like AppBar itself does.
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandedAppBar({super.key, required this.title, this.subtitle, this.actions, this.bottom});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  /// A TabBar, typically - same slot as AppBar's own `bottom`.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      titleSpacing: 16,
      bottom: bottom,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 30),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
      actions: actions,
    );
  }
}
