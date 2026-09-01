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

/// A plain FutureProvider - "fetch once, cache the result" - since this
/// provider itself only ever reads. AdminCategoryController is what
/// mutates categories (add/rename/delete) and invalidates this provider
/// afterwards so every screen watching it picks up the change.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).fetchCategories(),
);
