import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/provider_detail.dart';
import '../domain/provider_profile.dart';
import 'provider_profile_controller.dart';

/// Customer-facing search - never mutated from inside the app (there's no
/// "edit someone else's profile" action), so a plain FutureProvider.family
/// is enough, same reasoning as categoriesProvider. The family argument is
/// a record of both filters (rather than two separate `.family` providers)
/// since they combine into one request - Dart records compare by value, so
/// ProviderListScreen changing either field re-fetches exactly as if this
/// were a single argument.
typedef ProviderBrowseQuery = ({String? categoryId, String? search});

final providerBrowseProvider = FutureProvider.family<List<ProviderProfile>, ProviderBrowseQuery>(
  (ref, query) => ref
      .watch(providerProfileRepositoryProvider)
      .browseProviders(categoryId: query.categoryId, search: query.search),
);

/// A provider's public detail page - profile plus their services.
final providerDetailProvider = FutureProvider.family<ProviderDetail, String>(
  (ref, providerId) => ref.watch(providerProfileRepositoryProvider).getProviderDetail(providerId),
);
