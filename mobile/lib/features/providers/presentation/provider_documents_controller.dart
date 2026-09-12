import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../data/provider_documents_api.dart';
import '../data/provider_documents_repository.dart';
import '../domain/provider_documents.dart';

final providerDocumentsApiProvider = Provider<ProviderDocumentsApi>(
  (ref) => ProviderDocumentsApi(ref.watch(apiClientProvider).dio),
);

final providerDocumentsRepositoryProvider = Provider<ProviderDocumentsRepository>(
  (ref) => ProviderDocumentsRepository(ref.watch(providerDocumentsApiProvider)),
);

class ProviderDocumentsController extends AsyncNotifier<ProviderDocuments> {
  @override
  Future<ProviderDocuments> build() {
    return ref.read(providerDocumentsRepositoryProvider).getMyDocuments();
  }

  Future<void> uploadId(XFile image) => _mutate((repo) => repo.uploadId(image));

  Future<void> uploadTradeCertificate(XFile image) => _mutate((repo) => repo.uploadTradeCertificate(image));

  Future<void> uploadSelfie(XFile image) => _mutate((repo) => repo.uploadSelfie(image));

  Future<void> submit() => _mutate((repo) => repo.submit());

  Future<void> _mutate(Future<ProviderDocuments> Function(ProviderDocumentsRepository repo) action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => action(ref.read(providerDocumentsRepositoryProvider)));
  }
}

final providerDocumentsControllerProvider =
    AsyncNotifierProvider<ProviderDocumentsController, ProviderDocuments>(ProviderDocumentsController.new);
