import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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

  /// [file] becomes this category's icon everywhere it's shown in the app -
  /// see Category.imageUrl's doc comment. Same multipart shape as every
  /// other image upload in this app (ChatApi.sendAttachment, ProviderApi's
  /// photo upload).
  Future<AdminCategory> uploadImage({required String categoryId, required XFile file}) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: file.name)});
    final response = await _dio.post<Map<String, dynamic>>('/admin/categories/$categoryId/image', data: formData);
    return AdminCategory.fromJson(response.data!);
  }

  /// Resets this category back to its default icon (CategoryStyle).
  Future<AdminCategory> removeImage(String categoryId) async {
    final response = await _dio.delete<Map<String, dynamic>>('/admin/categories/$categoryId/image');
    return AdminCategory.fromJson(response.data!);
  }
}
