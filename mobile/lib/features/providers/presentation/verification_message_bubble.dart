import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/verification_message.dart';

/// Shared by both sides of the verification conversation (provider's own
/// screen and admin's per-provider screen) - same visual shape as chat's
/// _MessageBubble, but [isMine] is decided by comparing senderRole to
/// whichever role is VIEWING, not by comparing a specific user id (this
/// is a role-to-role conversation, not user-to-user - "admin" is whichever
/// admin happens to reply).
class VerificationMessageBubble extends StatelessWidget {
  const VerificationMessageBubble({super.key, required this.message, required this.isMine});

  final VerificationMessage message;
  final bool isMine;

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = isMine ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final foreground = isMine ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.field)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMine) Text(message.senderName, style: textTheme.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.75))),
            Text(message.body, style: textTheme.bodyMedium?.copyWith(color: foreground)),
            const SizedBox(height: 2),
            Text(_formatTime(message.createdAt), style: textTheme.bodySmall?.copyWith(color: foreground.withValues(alpha: 0.75))),
          ],
        ),
      ),
    );
  }
}
