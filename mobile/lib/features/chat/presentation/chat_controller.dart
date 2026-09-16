import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../data/chat_api.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(apiClientProvider).dio),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(chatApiProvider)),
);

/// One booking's whole conversation - read-only from this provider's point
/// of view, same reasoning as providerReviewsProvider. SendMessageController
/// is what mutates (a plain text body or a photo/video attachment), and
/// invalidates this by bookingId afterwards. ChatScreen also connects a
/// ChatSocket for live push while it's open (see that class's doc comment).
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, bookingId) => ref.watch(chatRepositoryProvider).listMessages(bookingId),
);

/// Sending a message - its own dedicated controller, same reasoning as
/// SubmitReviewController: chatMessagesProvider's state doubles as "is the
/// conversation loading", which would make "did my send succeed" ambiguous
/// with an unrelated background refresh if this lived on that same
/// provider. Covers both a plain text send and an attachment send - a
/// screen can only be doing one or the other at once, so they share one
/// "is sending" state rather than needing two separate controllers.
class SendMessageController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> send({required String bookingId, required String body}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(chatRepositoryProvider).sendMessage(bookingId: bookingId, body: body);
      ref.invalidate(chatMessagesProvider(bookingId));
      return true;
    });
  }

  Future<void> sendAttachment({required String bookingId, required XFile file, String? caption}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(chatRepositoryProvider).sendAttachment(bookingId: bookingId, file: file, caption: caption);
      ref.invalidate(chatMessagesProvider(bookingId));
      return true;
    });
  }

  /// "Clear chat" - see ChatRepository.clearChat's doc comment. ChatScreen
  /// only calls this after an explicit confirmation dialog, since it's
  /// irreversible and empties the conversation for the other party too.
  Future<void> clearChat(String bookingId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(chatRepositoryProvider).clearChat(bookingId);
      ref.invalidate(chatMessagesProvider(bookingId));
      return true;
    });
  }
}

final sendMessageControllerProvider =
    AsyncNotifierProvider<SendMessageController, bool>(SendMessageController.new);
