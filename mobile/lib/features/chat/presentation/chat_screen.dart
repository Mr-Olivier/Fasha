import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/chat_message.dart';
import 'chat_controller.dart';

/// What ChatScreen needs from whichever booking card opened it - just the
/// booking id (to fetch/send messages) and the other party's display name
/// (for the app bar), rather than the whole Booking object neither of
/// which this screen otherwise uses.
class ChatScreenArgs {
  const ChatScreenArgs({required this.bookingId, required this.otherPartyName});

  final String bookingId;
  final String otherPartyName;
}

/// One booking's chat thread. Polls every few seconds while open - there's
/// no push/websocket wiring in this app (see Notification's doc comment for
/// the same reasoning applied to notifications), so this is the only way
/// to see a reply without manually backing out and re-entering.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatScreenArgs args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _pollInterval = Duration(seconds: 4);

  final _bodyController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      ref.invalidate(chatMessagesProvider(widget.args.bookingId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    await ref.read(sendMessageControllerProvider.notifier).send(bookingId: widget.args.bookingId, body: body);

    final state = ref.read(sendMessageControllerProvider);
    if (state.hasError) return;
    _bodyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.args.bookingId));
    final isSending = ref.watch(sendMessageControllerProvider).isLoading;
    final myUserId = ref.watch(authControllerProvider).valueOrNull?.userId;

    ref.listen(sendMessageControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.args.otherPartyName)),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const Center(child: Text('Could not load this conversation.')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      child: Text(
                        'No messages yet - say hello.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  );
                }
                // Newest at the bottom without any manual scroll-controller
                // bookkeeping: `reverse: true` pins index 0 to the bottom,
                // so the reversed list just puts the last message there.
                final reversed = messages.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  itemCount: reversed.length,
                  itemBuilder: (context, index) => _MessageBubble(
                    message: reversed[index],
                    isMine: reversed[index].senderId == myUserId,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Type a message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: isSending ? null : _send,
                    icon: isSending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
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
    final foreground = isMine ? Colors.white : colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.body, style: textTheme.bodyMedium?.copyWith(color: foreground)),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: textTheme.bodySmall?.copyWith(color: foreground.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}
