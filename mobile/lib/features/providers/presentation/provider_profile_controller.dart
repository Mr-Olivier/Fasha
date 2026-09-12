import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../data/provider_profile_api.dart';
import '../data/provider_profile_repository.dart';
import '../domain/provider_profile.dart';

final providerProfileApiProvider = Provider<ProviderProfileApi>(
  (ref) => ProviderProfileApi(ref.watch(apiClientProvider).dio),
);

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>(
  (ref) => ProviderProfileRepository(ref.watch(providerProfileApiProvider)),
);

/// `null` state means "this provider hasn't created a profile yet" -
/// ProviderProfileScreen uses that to decide whether to show a "create"
/// form or an "edit" form pre-filled with the existing values.
class ProviderProfileController extends AsyncNotifier<ProviderProfile?> {
  @override
  Future<ProviderProfile?> build() {
    return ref.read(providerProfileRepositoryProvider).fetchMyProfile();
  }

  Future<void> save({
    required String businessName,
    String? description,
    String? location,
    String? profileImageUrl,
    String? categoryId,
    int? yearsExperience,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(providerProfileRepositoryProvider).upsertMyProfile(
            businessName: businessName,
            description: description,
            location: location,
            profileImageUrl: profileImageUrl,
            categoryId: categoryId,
            yearsExperience: yearsExperience,
          ),
    );
  }

  Future<void> uploadPhoto(XFile image) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(providerProfileRepositoryProvider).uploadPhoto(image));
  }
}

final providerProfileControllerProvider =
    AsyncNotifierProvider<ProviderProfileController, ProviderProfile?>(ProviderProfileController.new);
