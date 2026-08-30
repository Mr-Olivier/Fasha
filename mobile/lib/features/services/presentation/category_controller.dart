import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/category_api.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';

final categoryApiProvider = Provider<CategoryApi>(
  (ref) => CategoryApi(ref.watch(apiClientProvider).dio),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(categoryApiProvider)),
);

/// Categories never change from inside the app (no create/edit endpoint
/// exists yet), so a plain FutureProvider - "fetch once, cache the result" -
/// is enough. No AsyncNotifier/mutation methods needed, unlike
/// AuthController or ServiceListingController.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).fetchCategories(),
);
