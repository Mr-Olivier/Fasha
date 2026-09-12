import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/verification_message_api.dart';
import '../data/verification_message_repository.dart';
import '../domain/verification_message.dart';

final verificationMessageApiProvider = Provider<VerificationMessageApi>(
  (ref) => VerificationMessageApi(ref.watch(apiClientProvider).dio),
);

final verificationMessageRepositoryProvider = Provider<VerificationMessageRepository>(
  (ref) => VerificationMessageRepository(ref.watch(verificationMessageApiProvider)),
);

/// A provider's own verification conversation - GetVerifiedScreen's "Message
/// admin" entry point.
final myVerificationMessagesProvider = FutureProvider<List<VerificationMessage>>(
  (ref) => ref.watch(verificationMessageRepositoryProvider).listMine(),
);

/// Same conversation, from admin's side - keyed by providerProfileId since
/// one admin account opens many different providers' threads.
final adminVerificationMessagesProvider = FutureProvider.family<List<VerificationMessage>, String>(
  (ref, providerProfileId) => ref.watch(verificationMessageRepositoryProvider).listForProvider(providerProfileId),
);

/// Sending as the provider - its own dedicated controller, same reasoning
/// as SendMessageController (see its doc comment): the messages list's own
/// state doubles as "is the conversation loading", which would make "did
/// my send succeed" ambiguous with an unrelated background poll.
class SendMyVerificationMessageController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> send(String body) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(verificationMessageRepositoryProvider).sendMine(body);
      ref.invalidate(myVerificationMessagesProvider);
      return true;
    });
  }
}

final sendMyVerificationMessageControllerProvider =
    AsyncNotifierProvider<SendMyVerificationMessageController, bool>(SendMyVerificationMessageController.new);

/// Sending as admin, into a specific provider's thread.
class SendAdminVerificationMessageController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> send({required String providerProfileId, required String body}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(verificationMessageRepositoryProvider).sendAsAdmin(providerProfileId: providerProfileId, body: body);
      ref.invalidate(adminVerificationMessagesProvider(providerProfileId));
      return true;
    });
  }
}

final sendAdminVerificationMessageControllerProvider =
    AsyncNotifierProvider<SendAdminVerificationMessageController, bool>(SendAdminVerificationMessageController.new);
