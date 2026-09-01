import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../services/domain/category.dart';
import '../../services/presentation/category_controller.dart';
import '../data/admin_category_api.dart';
import '../data/admin_category_repository.dart';

final adminCategoryApiProvider = Provider<AdminCategoryApi>(
  (ref) => AdminCategoryApi(ref.watch(apiClientProvider).dio),
);

final adminCategoryRepositoryProvider = Provider<AdminCategoryRepository>(
  (ref) => AdminCategoryRepository(ref.watch(adminCategoryApiProvider)),
);

/// State is the full category list, same shape as ServiceListingController -
/// add/update/delete all re-fetch the whole list afterwards rather than
/// patching it in place, and also invalidate categoriesProvider so every
/// other screen reading it (the service form's dropdown, home's category
/// grid) picks up the change too.
class AdminCategoryController extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() {
    return ref.read(categoryRepositoryProvider).fetchCategories();
  }

  Future<void> addCategory({required String name, String? description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).create(name: name, description: description);
      ref.invalidate(categoriesProvider);
      return ref.read(categoryRepositoryProvider).fetchCategories();
    });
  }

  Future<void> updateCategory({required String categoryId, required String name, String? description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).update(categoryId: categoryId, name: name, description: description);
      ref.invalidate(categoriesProvider);
      return ref.read(categoryRepositoryProvider).fetchCategories();
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).delete(categoryId);
      ref.invalidate(categoriesProvider);
      return ref.read(categoryRepositoryProvider).fetchCategories();
    });
  }
}

final adminCategoryControllerProvider =
    AsyncNotifierProvider<AdminCategoryController, List<Category>>(AdminCategoryController.new);
