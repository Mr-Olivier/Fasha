import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/chat_screen.dart';
import '../theme/app_theme.dart';

/// A tappable "Message {name}" row - shown next to CallContactRow once a
/// booking allows contact (see BookingStatus.allowsContact on the backend),
/// as the other way the two parties can reach each other.
class ChatEntryRow extends StatelessWidget {
  const ChatEntryRow({super.key, required this.bookingId, required this.name});

  final String bookingId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.push('/chat', extra: ChatScreenArgs(bookingId: bookingId, otherPartyName: name)),
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Message $name',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
