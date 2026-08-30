import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/service_listing.dart';
import 'service_listing_api.dart';

class ServiceListingRepository {
  const ServiceListingRepository(this._api);

  final ServiceListingApi _api;

  Future<List<ServiceListing>> listMyServices() async {
    try {
      return await _api.listMyServices();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ServiceListing> addService({
    required String categoryId,
    required String name,
    String? description,
    required double price,
  }) async {
    try {
      return await _api.addService(categoryId: categoryId, name: name, description: description, price: price);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ServiceListing> updateService({
    required String serviceId,
    required String categoryId,
    required String name,
    String? description,
    required double price,
  }) async {
    try {
      return await _api.updateService(
        serviceId: serviceId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
