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
/// one has nothing left for the admin to decide. Used by the admin
/// Overview's "Needs your action" section.
final pendingProvidersProvider = FutureProvider<List<PendingProvider>>(
  (ref) => ref.watch(adminProviderRepositoryProvider).listProviders(status: VerificationStatus.pending),
);

/// The full Providers management screen's data - a `.family` keyed by the
/// status filter chip the admin currently has selected (null = "All"), so
/// switching chips is just watching a different, independently-cached
/// instance of this same provider rather than refetching/losing scroll
/// position on every tap.
final adminProvidersByStatusProvider = FutureProvider.family<List<PendingProvider>, VerificationStatus?>(
  (ref, status) => ref.watch(adminProviderRepositoryProvider).listProviders(status: status),
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

/// Admin deleting one of a provider's KYC documents to free storage - its
/// own dedicated controller, same "was loading, now has a value" ambiguity
/// reasoning as DecideProviderController above.
class AdminDeleteDocumentController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> delete({required String providerId, required String documentType}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminProviderRepositoryProvider).deleteDocument(providerId: providerId, documentType: documentType);
      return true;
    });
  }
}

final adminDeleteDocumentControllerProvider =
    AsyncNotifierProvider<AdminDeleteDocumentController, bool>(AdminDeleteDocumentController.new);
