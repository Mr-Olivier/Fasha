import 'package:dio/dio.dart';

import '../domain/service_listing.dart';

/// Raw HTTP calls to GET/POST /api/providers/me/services and
/// PUT .../{serviceId}.
class ServiceListingApi {
  const ServiceListingApi(this._dio);

  final Dio _dio;

  Future<List<ServiceListing>> listMyServices() async {
    final response = await _dio.get<List<dynamic>>('/providers/me/services');
    return response.data!.map((json) => ServiceListing.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ServiceListing> addService({
    required String categoryId,
    required String name,
    String? description,
    required double price,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/providers/me/services',
      data: {'categoryId': categoryId, 'name': name, 'description': description, 'price': price},
    );
    return ServiceListing.fromJson(response.data!);
  }

  Future<ServiceListing> updateService({
    required String serviceId,
    required String categoryId,
    required String name,
    String? description,
    required double price,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/providers/me/services/$serviceId',
      data: {'categoryId': categoryId, 'name': name, 'description': description, 'price': price},
    );
    return ServiceListing.fromJson(response.data!);
  }
}
