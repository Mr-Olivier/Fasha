import 'package:dio/dio.dart';

import '../../services/domain/category.dart';

/// Raw HTTP calls to POST/PATCH/DELETE /api/admin/categories - admin-only,
/// enforced server-side by @PreAuthorize("hasRole('ADMIN')") on
/// AdminCategoryController. Reading the list still goes through the
/// existing public CategoryApi (GET /api/categories) - no need to duplicate
/// that endpoint here.
class AdminCategoryApi {
  const AdminCategoryApi(this._dio);

  final Dio _dio;

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
