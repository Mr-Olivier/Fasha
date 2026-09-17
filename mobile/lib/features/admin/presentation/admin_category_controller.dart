import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../services/domain/category.dart';
import '../../services/presentation/category_controller.dart';
import '../data/admin_category_api.dart';
import '../data/admin_category_repository.dart';
import '../domain/admin_category.dart';

final adminCategoryApiProvider = Provider<AdminCategoryApi>(
  (ref) => AdminCategoryApi(ref.watch(apiClientProvider).dio),
);

final adminCategoryRepositoryProvider = Provider<AdminCategoryRepository>(
  (ref) => AdminCategoryRepository(ref.watch(adminCategoryApiProvider)),
);

/// State is the full category list (including hidden ones - see
/// AdminCategory's doc comment), same shape as ServiceListingController -
/// every mutation re-fetches the whole list afterwards rather than patching
/// it in place, and also invalidates categoriesProvider so every other
/// screen reading the PUBLIC list (the service form's dropdown, home's
/// category grid) picks up the change too.
class AdminCategoryController extends AsyncNotifier<List<AdminCategory>> {
  @override
  Future<List<AdminCategory>> build() {
    return ref.read(adminCategoryRepositoryProvider).listAll();
  }

  /// Returns the newly created category (null if the create failed - see
  /// [state] for the error) so CategoryFormScreen can immediately route
  /// into editing it, where the icon-upload UI actually lives - a category
  /// needs a real id to upload against, which doesn't exist until this
  /// call returns.
  Future<Category?> addCategory({required String name, String? description}) async {
    state = const AsyncValue.loading();
    Category? created;
    state = await AsyncValue.guard(() async {
      created = await ref.read(adminCategoryRepositoryProvider).create(name: name, description: description);
      ref.invalidate(categoriesProvider);
      return ref.read(adminCategoryRepositoryProvider).listAll();
    });
    return created;
  }

  Future<void> updateCategory({required String categoryId, required String name, String? description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).update(categoryId: categoryId, name: name, description: description);
      ref.invalidate(categoriesProvider);
      return ref.read(adminCategoryRepositoryProvider).listAll();
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).delete(categoryId);
      ref.invalidate(categoriesProvider);
      return ref.read(adminCategoryRepositoryProvider).listAll();
    });
  }

  Future<void> setVisibility({required String categoryId, required bool active}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).setVisibility(categoryId: categoryId, active: active);
      ref.invalidate(categoriesProvider);
      return ref.read(adminCategoryRepositoryProvider).listAll();
    });
  }

  Future<void> uploadImage({required String categoryId, required XFile file}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).uploadImage(categoryId: categoryId, file: file);
      ref.invalidate(categoriesProvider);
      return ref.read(adminCategoryRepositoryProvider).listAll();
    });
  }

  Future<void> removeImage(String categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminCategoryRepositoryProvider).removeImage(categoryId);
      ref.invalidate(categoriesProvider);
      return ref.read(adminCategoryRepositoryProvider).listAll();
    });
  }
}

final adminCategoryControllerProvider =
    AsyncNotifierProvider<AdminCategoryController, List<AdminCategory>>(AdminCategoryController.new);
