import 'package:dio/dio.dart';

import '../domain/service_duration.dart';
import '../domain/service_listing.dart';

/// Raw HTTP calls to GET/POST /api/providers/me/services,
/// PUT .../{serviceId}, and PATCH .../{serviceId}/visibility.
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
    required ServiceDuration duration,
    required bool visible,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/providers/me/services',
      data: {
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'duration': duration.wireName,
        'visible': visible,
      },
    );
    return ServiceListing.fromJson(response.data!);
  }

  Future<ServiceListing> updateService({
    required String serviceId,
    required String categoryId,
    required String name,
    String? description,
    required double price,
    required ServiceDuration duration,
    required bool visible,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/providers/me/services/$serviceId',
      data: {
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'duration': duration.wireName,
        'visible': visible,
      },
    );
    return ServiceListing.fromJson(response.data!);
  }

  Future<ServiceListing> setVisibility({required String serviceId, required bool visible}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/providers/me/services/$serviceId/visibility',
      data: {'visible': visible},
    );
    return ServiceListing.fromJson(response.data!);
  }
}
