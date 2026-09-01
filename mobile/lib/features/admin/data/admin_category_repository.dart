import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../services/domain/category.dart';
import 'admin_category_api.dart';

class AdminCategoryRepository {
  const AdminCategoryRepository(this._api);

  final AdminCategoryApi _api;

  Future<Category> create({required String name, String? description}) async {
    try {
      return await _api.create(name: name, description: description);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Category> update({required String categoryId, required String name, String? description}) async {
    try {
      return await _api.update(categoryId: categoryId, name: name, description: description);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String categoryId) async {
    try {
      await _api.delete(categoryId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
