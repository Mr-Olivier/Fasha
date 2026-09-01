import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// is what mutates, and invalidates this by bookingId afterwards.
/// ChatScreen also refreshes it on a short timer while it's open, since
/// there's no push/websocket wiring to know when the other side replies.
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, bookingId) => ref.watch(chatRepositoryProvider).listMessages(bookingId),
);

/// Sending a message - its own dedicated controller, same reasoning as
/// SubmitReviewController: chatMessagesProvider's state doubles as "is the
/// conversation loading" (including ChatScreen's periodic poll), which
/// would make "did my send succeed" ambiguous with an unrelated background
/// poll if this lived on that same provider.
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
}

final sendMessageControllerProvider =
    AsyncNotifierProvider<SendMessageController, bool>(SendMessageController.new);
