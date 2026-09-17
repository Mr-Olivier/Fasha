import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../services/domain/category.dart';
import '../domain/admin_category.dart';
import 'admin_category_api.dart';

class AdminCategoryRepository {
  const AdminCategoryRepository(this._api);

  final AdminCategoryApi _api;

  Future<List<AdminCategory>> listAll() async {
    try {
      return await _api.listAll();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminCategory> setVisibility({required String categoryId, required bool active}) async {
    try {
      return await _api.setVisibility(categoryId: categoryId, active: active);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  Future<AdminCategory> uploadImage({required String categoryId, required XFile file}) async {
    try {
      return await _api.uploadImage(categoryId: categoryId, file: file);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminCategory> removeImage(String categoryId) async {
    try {
      return await _api.removeImage(categoryId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
