import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../providers/domain/verification_status.dart';
import '../data/admin_provider_api.dart';
import '../data/admin_provider_repository.dart';
import '../domain/pending_provider.dart';

final adminProviderApiProvider = Provider<AdminProviderApi>(
  (ref) => AdminProviderApi(ref.watch(apiClientProvider).dio),
);

final adminProviderRepositoryProvider = Provider<AdminProviderRepository>(
  (ref) => AdminProviderRepository(ref.watch(adminProviderApiProvider)),
);

/// The approval queue - only PENDING providers, since an approved/rejected
/// one has nothing left for the admin to decide.
final pendingProvidersProvider = FutureProvider<List<PendingProvider>>(
  (ref) => ref.watch(adminProviderRepositoryProvider).listProviders(status: VerificationStatus.pending),
);

/// Approving/rejecting one application - its own dedicated `AsyncNotifier<bool>`
/// rather than reusing pendingProvidersProvider's own state, for the same
/// reason RequestBookingController and SubmitReviewController are separate
/// from the list providers they sit next to: this provider's initial list
/// fetch and a successful decision would otherwise look identical (both are
/// "was loading, now has a value"), which caused a real false-success-toast
/// bug the first two times this pattern was missed. See RequestBookingController's
/// doc comment for the full story.
class DecideProviderController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> decide({required String providerId, required bool approved}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminProviderRepositoryProvider).decide(providerId: providerId, approved: approved);
      // So the approved/rejected provider drops out of the pending queue.
      ref.invalidate(pendingProvidersProvider);
      return true;
    });
  }
}

final decideProviderControllerProvider =
    AsyncNotifierProvider<DecideProviderController, bool>(DecideProviderController.new);
