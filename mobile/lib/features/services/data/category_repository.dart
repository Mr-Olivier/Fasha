import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/category.dart';
import 'category_api.dart';

class CategoryRepository {
  const CategoryRepository(this._api);

  final CategoryApi _api;

  Future<List<Category>> fetchCategories() async {
    try {
      return await _api.fetchCategories();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
