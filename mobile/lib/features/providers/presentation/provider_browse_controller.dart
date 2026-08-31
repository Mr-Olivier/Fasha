import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/provider_detail.dart';
import '../domain/provider_profile.dart';
import 'provider_profile_controller.dart';

/// Customer-facing search - never mutated from inside the app (there's no
/// "edit someone else's profile" action), so a plain FutureProvider.family
/// is enough, same reasoning as categoriesProvider. `.family` because the
/// result depends on an argument (which category, or null for "all").
final providerBrowseProvider = FutureProvider.family<List<ProviderProfile>, String?>(
  (ref, categoryId) => ref.watch(providerProfileRepositoryProvider).browseProviders(categoryId: categoryId),
);

/// A provider's public detail page - profile plus their services.
final providerDetailProvider = FutureProvider.family<ProviderDetail, String>(
  (ref, providerId) => ref.watch(providerProfileRepositoryProvider).getProviderDetail(providerId),
);
