import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/verification_message.dart';
import 'verification_message_bubble.dart';
import 'verification_message_controller.dart';

/// A provider's own side of the D7 verification conversation with admin -
/// reached from GetVerifiedScreen. Polls every few seconds while open, same
/// reasoning as ChatScreen (no push/websocket wiring in this app).
class VerificationChatScreen extends ConsumerStatefulWidget {
  const VerificationChatScreen({super.key});

  @override
  ConsumerState<VerificationChatScreen> createState() => _VerificationChatScreenState();
}

class _VerificationChatScreenState extends ConsumerState<VerificationChatScreen> {
  static const _pollInterval = Duration(seconds: 4);

  final _bodyController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) => ref.invalidate(myVerificationMessagesProvider));
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

    await ref.read(sendMyVerificationMessageControllerProvider.notifier).send(body);

    final state = ref.read(sendMyVerificationMessageControllerProvider);
    if (state.hasError) return;
    _bodyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(myVerificationMessagesProvider);
    final isSending = ref.watch(sendMyVerificationMessageControllerProvider).isLoading;

    ref.listen(sendMyVerificationMessageControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Message admin')),
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
                        'Ask admin here if you\'re not sure what to submit, or why your last submission wasn\'t approved.',
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
                    isMine: reversed[index].senderRole == VerificationMessageSenderRole.provider,
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
