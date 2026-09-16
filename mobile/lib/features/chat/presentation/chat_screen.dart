import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/chat_socket.dart';
import '../domain/chat_message.dart';
import 'attachment_picker_sheet.dart';
import 'chat_attachment_view.dart';
import 'chat_controller.dart';

/// What ChatScreen needs from whichever booking card opened it - just the
/// booking id (to fetch/send messages) and the other party's display name
/// (for the app bar), rather than the whole Booking object neither of
/// which this screen otherwise uses.
class ChatScreenArgs {
  const ChatScreenArgs({required this.bookingId, required this.otherPartyName, this.pendingAttachment});

  final String bookingId;
  final String otherPartyName;

  /// Set only when FashaApp's own startup recovery (see
  /// PendingAttachmentStore) is navigating here to finish sending a
  /// photo/video whose capture survived an Android process kill but whose
  /// original AttachmentPickerSheet call didn't - null on every normal
  /// "the user tapped into this chat" navigation.
  final ({XFile file, bool isVideo})? pendingAttachment;
}

/// Don't bother re-sending "typing" more than once in this window - a
/// client mashing the keyboard would otherwise flood the socket with one
/// frame per keystroke for no benefit (the receiving side only ever shows
/// "typing..." either way).
const _typingResendInterval = Duration(seconds: 2);

/// How long "X is typing..." stays up after the last signal before
/// reverting to the plain title - long enough to survive a brief pause
/// mid-sentence, short enough that it doesn't linger once they've actually
/// stopped (there's no explicit "stopped typing" signal - see
/// ChatWebSocketHandler, which only ever relays "typing", never its
/// opposite).
const _typingIndicatorTimeout = Duration(seconds: 3);

/// One booking's chat thread - text, photos, and short videos, backed by
/// ChatWebSocketHandler for live delivery of the other party's messages
/// AND their typing presence (see ChatSocket's doc comment). If the
/// connection can't be established (token missing/expired, server
/// unreachable) this screen still works via the normal REST load; it just
/// won't update again until reopened, same as this app's original polling
/// behaviour on a failed request.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatScreenArgs args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _bodyController = TextEditingController();
  ChatSocket? _socket;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<String>? _typingSubscription;
  StreamSubscription<void>? _clearedSubscription;
  DateTime? _lastTypingSentAt;
  Timer? _typingClearTimer;
  bool _otherPartyTyping = false;

  @override
  void initState() {
    super.initState();
    final token = ref.read(authControllerProvider).valueOrNull?.token;
    if (token == null) return;

    final socket = ChatSocket(bookingId: widget.args.bookingId, token: token);
    _socket = socket;
    _messageSubscription = socket.messages.listen((_) {
      // The socket only tells us "something new arrived" - re-fetching via
      // the normal REST list keeps a single source of truth instead of
      // this screen maintaining its own separate copy that could drift
      // (e.g. missing a message that arrived before this screen connected).
      ref.invalidate(chatMessagesProvider(widget.args.bookingId));
    });
    _typingSubscription = socket.typingUserIds.listen((_) => _onOtherPartyTyping());
    _clearedSubscription = socket.cleared.listen((_) => ref.invalidate(chatMessagesProvider(widget.args.bookingId)));

    // Normally null. Set when FashaApp's own startup check recovered a
    // photo/video whose capture survived an Android process kill (see
    // PendingAttachmentStore and ChatScreenArgs.pendingAttachment) and
    // navigated here to finish the job - a post-frame callback because
    // AttachmentPreviewSheet needs a BuildContext that's actually in the
    // tree, which isn't true yet inside initState itself.
    final pending = widget.args.pendingAttachment;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_sendPickedAttachment(pending.file, pending.isVideo));
      });
    }
  }

  void _onOtherPartyTyping() {
    setState(() => _otherPartyTyping = true);
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(_typingIndicatorTimeout, () {
      if (mounted) setState(() => _otherPartyTyping = false);
    });
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    if (_lastTypingSentAt != null && now.difference(_lastTypingSentAt!) < _typingResendInterval) return;
    _lastTypingSentAt = now;
    _socket?.sendTyping();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _clearedSubscription?.cancel();
    _typingClearTimer?.cancel();
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

  Future<void> _pickAndSendAttachment() async {
    final picked = await AttachmentPickerSheet.show(
      context,
      bookingId: widget.args.bookingId,
      otherPartyName: widget.args.otherPartyName,
    );
    if (picked == null || !mounted) return;
    await _sendPickedAttachment(picked.file, picked.isVideo);
  }

  Future<void> _sendPickedAttachment(XFile file, bool isVideo) async {
    final caption = await AttachmentPreviewSheet.show(context, file: file, isVideo: isVideo);
    if (caption == null || !mounted) return;

    await ref.read(sendMessageControllerProvider.notifier).sendAttachment(
          bookingId: widget.args.bookingId,
          file: file,
          caption: caption,
        );
  }

  /// Irreversible and empties the conversation for the OTHER party too
  /// (see MessageService.clearChat's doc comment) - a plain confirm dialog
  /// rather than a swipe/long-press shortcut, same weight WhatsApp itself
  /// gives "Delete chat".
  Future<void> _confirmAndClearChat() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this chat?'),
        content: Text(
          'This permanently deletes every message and photo/video with ${widget.args.otherPartyName}. '
          'This can\'t be undone, and removes it for both of you.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Clear chat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(sendMessageControllerProvider.notifier).clearChat(widget.args.bookingId);
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.args.otherPartyName),
            // Same slot WhatsApp uses for "online"/"last seen" - here it's
            // the one piece of presence this app actually has, driven live
            // by ChatSocket.typingUserIds rather than anything persisted.
            if (_otherPartyTyping)
              Text(
                'typing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_confirmAndClearChat())),
                child: const Text('Clear chat'),
              ),
            ],
          ),
        ],
      ),
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
                  IconButton(
                    onPressed: isSending ? null : _pickAndSendAttachment,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Share a photo or video',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Type a message'),
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: isSending ? null : _send,
                    icon: isSending
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
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
    final foreground = isMine ? colorScheme.onPrimary : colorScheme.onSurface;
    final attachmentPath = '/bookings/${message.bookingId}/messages/${message.id}/attachment';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.xs),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.attachmentType == ChatAttachmentType.image) ChatImageAttachment(path: attachmentPath),
            if (message.attachmentType == ChatAttachmentType.video) ChatVideoAttachment(path: attachmentPath),
            if (message.body != null && message.body!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Text(message.body!, style: textTheme.bodyMedium?.copyWith(color: foreground)),
              ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm, bottom: 2),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
