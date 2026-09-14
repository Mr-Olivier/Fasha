import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/chat_socket.dart';
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

/// One booking's chat thread. Connects to ChatWebSocketHandler on the
/// backend for live delivery of the other party's messages - see
/// ChatSocket's doc comment. If the connection can't be established (token
/// missing/expired, server unreachable) this screen still works via the
/// normal REST load; it just won't update again until reopened, same as
/// this app's original polling behavior on a failed request.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatScreenArgs args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _bodyController = TextEditingController();
  ChatSocket? _socket;
  StreamSubscription<ChatMessage>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    final token = ref.read(authControllerProvider).valueOrNull?.token;
    if (token == null) return;

    final socket = ChatSocket(bookingId: widget.args.bookingId, token: token);
    _socket = socket;
    _socketSubscription = socket.messages.listen((_) {
      // The socket only tells us "something new arrived" - re-fetching via
      // the normal REST list keeps a single source of truth instead of
      // this screen maintaining its own separate copy that could drift
      // (e.g. missing a message that arrived before this screen connected).
      ref.invalidate(chatMessagesProvider(widget.args.bookingId));
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socket?.dispose();
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: textTheme.bodySmall?.copyWith(color: foreground.withValues(alpha: 0.75)),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  // Read receipt: a single check once it's sent, a double
                  // check once the other party has opened this
                  // conversation (message.read) - only shown on OUR OWN
                  // bubbles, since whether the other person read what WE
                  // sent is the only direction that's meaningful to show.
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 14,
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
