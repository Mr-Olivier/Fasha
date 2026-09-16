import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_theme.dart';
import '../theme/status_colors.dart';

enum _ToastKind { success, error, info }

/// A single, consistent way to show a toast/snackbar across the whole app -
/// colored, with an icon, so success and error are visually distinct at a
/// glance instead of every screen showing an identical plain-text bar.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) => _show(context, message, _ToastKind.success);

  static void error(BuildContext context, String message) => _show(context, message, _ToastKind.error);

  static void info(BuildContext context, String message) => _show(context, message, _ToastKind.info);

  /// Every screen in this app follows the exact same pattern for a failed
  /// API call - unwrap ApiException's message, or fall back to a generic
  /// one for anything else (a network drop, a bug). Centralizing it here
  /// means that fallback text only needs to be right in one place.
  static void apiError(BuildContext context, Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    AppToast.error(context, message);
  }

  static void _show(BuildContext context, String message, _ToastKind kind) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, background, foreground) = switch (kind) {
      _ToastKind.success => (Icons.check_circle_outline, StatusColors.positive(context), colorScheme.onPrimary),
      _ToastKind.error => (Icons.error_outline, StatusColors.negative(context), colorScheme.onError),
      _ToastKind.info => (Icons.info_outline, colorScheme.secondary, colorScheme.onSecondary),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.gutter),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message, style: TextStyle(color: foreground))),
            ],
          ),
        ),
      );
  }
}
