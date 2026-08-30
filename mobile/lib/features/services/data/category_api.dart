import 'package:dio/dio.dart';

import '../domain/category.dart';

class CategoryApi {
  const CategoryApi(this._dio);

  final Dio _dio;

  Future<List<Category>> fetchCategories() async {
    final response = await _dio.get<List<dynamic>>('/categories');
    return response.data!.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }
}
