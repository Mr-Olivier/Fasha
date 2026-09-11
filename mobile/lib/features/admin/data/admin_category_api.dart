import 'package:dio/dio.dart';

import '../../services/domain/category.dart';
import '../domain/admin_category.dart';

/// Raw HTTP calls to /api/admin/categories - admin-only, enforced
/// server-side by @PreAuthorize("hasRole('ADMIN')") on
/// AdminCategoryController. GET here is a separate, richer endpoint than
/// the public CategoryApi's GET /api/categories: it includes hidden
/// categories (an admin needs to see one to un-hide it) plus per-category
/// provider/booking counts.
class AdminCategoryApi {
  const AdminCategoryApi(this._dio);

  final Dio _dio;

  Future<List<AdminCategory>> listAll() async {
    final response = await _dio.get<List<dynamic>>('/admin/categories');
    return response.data!.map((e) => AdminCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminCategory> setVisibility({required String categoryId, required bool active}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/categories/$categoryId/visibility',
      data: {'active': active},
    );
    return AdminCategory.fromJson(response.data!);
  }

  Future<Category> create({required String name, String? description}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/categories',
      data: {'name': name, 'description': description},
    );
    return Category.fromJson(response.data!);
  }

  Future<Category> update({required String categoryId, required String name, String? description}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/categories/$categoryId',
      data: {'name': name, 'description': description},
    );
    return Category.fromJson(response.data!);
  }

  Future<void> delete(String categoryId) {
    return _dio.delete('/admin/categories/$categoryId');
  }
}
