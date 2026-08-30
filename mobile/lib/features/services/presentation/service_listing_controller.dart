import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/service_listing_api.dart';
import '../data/service_listing_repository.dart';
import '../domain/service_listing.dart';

final serviceListingApiProvider = Provider<ServiceListingApi>(
  (ref) => ServiceListingApi(ref.watch(apiClientProvider).dio),
);

final serviceListingRepositoryProvider = Provider<ServiceListingRepository>(
  (ref) => ServiceListingRepository(ref.watch(serviceListingApiProvider)),
);

/// State is the provider's full list of services. add/update re-fetch the
/// whole list afterwards rather than patching it in place locally - simpler
/// to reason about and get right, and the list is small enough (one
/// provider's own services) that re-fetching costs nothing noticeable.
class ServiceListingController extends AsyncNotifier<List<ServiceListing>> {
  @override
  Future<List<ServiceListing>> build() {
    return ref.read(serviceListingRepositoryProvider).listMyServices();
  }

  Future<void> addService({
    required String categoryId,
    required String name,
    String? description,
    required double price,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceListingRepositoryProvider);
      await repository.addService(categoryId: categoryId, name: name, description: description, price: price);
      return repository.listMyServices();
    });
  }

  Future<void> updateService({
    required String serviceId,
    required String categoryId,
    required String name,
    String? description,
    required double price,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceListingRepositoryProvider);
      await repository.updateService(
        serviceId: serviceId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
      );
      return repository.listMyServices();
    });
  }
}

final serviceListingControllerProvider =
    AsyncNotifierProvider<ServiceListingController, List<ServiceListing>>(ServiceListingController.new);
