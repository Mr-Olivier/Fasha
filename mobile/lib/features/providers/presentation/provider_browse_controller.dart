import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/provider_detail.dart';
import '../domain/provider_profile.dart';
import 'provider_profile_controller.dart';

/// Customer-facing search - never mutated from inside the app (there's no
/// "edit someone else's profile" action), so a plain FutureProvider.family
/// is enough, same reasoning as categoriesProvider. The family argument is
/// a record of every filter (rather than one `.family` per filter) since
/// they all combine into one request - Dart records compare by value, so
/// ProviderListScreen/FiltersSheet changing any field re-fetches exactly as
/// if this were a single argument.
///
/// [district] is deliberately NOT sent to the backend - ProviderProfile has
/// no structured district field, only a free-text `location` (see
/// ProviderProfileService's doc comment on the backend), so the Filters
/// sheet's district chips are applied here, client-side, as a substring
/// match against `location` - the same thing typing a district name into
/// the search box would already do, just exposed as tappable chips.
typedef ProviderBrowseQuery = ({
  String? categoryId,
  String? search,
  String? district,
  double? minRating,
  double? maxPrice,
});

final providerBrowseProvider = FutureProvider.family<List<ProviderProfile>, ProviderBrowseQuery>(
  (ref, query) async {
    final results = await ref.watch(providerProfileRepositoryProvider).browseProviders(
          categoryId: query.categoryId,
          search: query.search,
          minRating: query.minRating,
          maxPrice: query.maxPrice,
        );
    if (query.district == null || query.district!.isEmpty) return results;
    final needle = query.district!.toLowerCase();
    return results.where((p) => (p.location ?? '').toLowerCase().contains(needle)).toList();
  },
);

/// A provider's public detail page - profile plus their services.
final providerDetailProvider = FutureProvider.family<ProviderDetail, String>(
  (ref, providerId) => ref.watch(providerProfileRepositoryProvider).getProviderDetail(providerId),
);

/// A customer's saved providers (GET /api/favorites) - the Profile tab's
/// "Favorites" entry and the Explore tab's favorites view.
final favoriteProvidersProvider = FutureProvider<List<ProviderProfile>>(
  (ref) => ref.watch(providerProfileRepositoryProvider).listFavorites(),
);

/// Toggling the heart icon on a Provider Profile screen. Kept separate from
/// providerDetailProvider/providerBrowseProvider (which are plain
/// FutureProviders, not mutable) - same "reads and writes don't share a
/// provider" split as RequestBookingController vs MyBookingsController.
class FavoriteToggleController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggle(String providerId, {required bool currentlyFavorited}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(providerProfileRepositoryProvider);
      if (currentlyFavorited) {
        await repository.unfavorite(providerId);
      } else {
        await repository.favorite(providerId);
      }
      // Both the detail page and any list/favorites screen showing this
      // provider's heart state need to reflect the change next time
      // they're read.
      ref.invalidate(providerDetailProvider);
      ref.invalidate(providerBrowseProvider);
      ref.invalidate(favoriteProvidersProvider);
    });
  }
}

final favoriteToggleControllerProvider = AsyncNotifierProvider<FavoriteToggleController, void>(FavoriteToggleController.new);
