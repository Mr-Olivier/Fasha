import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/verification_message.dart';
import 'verification_message_bubble.dart';
import 'verification_message_controller.dart';

/// What opening this screen needs from whichever provider card launched it
/// - same pattern as ChatScreenArgs (features/chat).
class AdminVerificationChatArgs {
  const AdminVerificationChatArgs({required this.providerProfileId, required this.providerName});

  final String providerProfileId;
  final String providerName;
}

/// Admin's side of the D7 verification conversation with one provider -
/// reached from the admin Providers screen. [providerName] is just for the
/// app bar title; all reads/writes are keyed by [providerProfileId].
class AdminVerificationChatScreen extends ConsumerStatefulWidget {
  const AdminVerificationChatScreen({super.key, required this.providerProfileId, required this.providerName});

  final String providerProfileId;
  final String providerName;

  @override
  ConsumerState<AdminVerificationChatScreen> createState() => _AdminVerificationChatScreenState();
}

class _AdminVerificationChatScreenState extends ConsumerState<AdminVerificationChatScreen> {
  static const _pollInterval = Duration(seconds: 4);

  final _bodyController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      ref.invalidate(adminVerificationMessagesProvider(widget.providerProfileId));
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

    await ref
        .read(sendAdminVerificationMessageControllerProvider.notifier)
        .send(providerProfileId: widget.providerProfileId, body: body);

    final state = ref.read(sendAdminVerificationMessageControllerProvider);
    if (state.hasError) return;
    _bodyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(adminVerificationMessagesProvider(widget.providerProfileId));
    final isSending = ref.watch(sendAdminVerificationMessageControllerProvider).isLoading;

    ref.listen(sendAdminVerificationMessageControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.providerName)),
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
                        'Tell ${widget.providerName} what\'s missing or unclear on their documents.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  );
                }
                final reversed = messages.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  itemCount: reversed.length,
                  itemBuilder: (context, index) => VerificationMessageBubble(
                    message: reversed[index],
                    isMine: reversed[index].senderRole == VerificationMessageSenderRole.admin,
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
