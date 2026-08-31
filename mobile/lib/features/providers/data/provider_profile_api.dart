import 'package:dio/dio.dart';

import '../domain/provider_detail.dart';
import '../domain/provider_profile.dart';

/// Raw HTTP calls to GET/PUT /api/providers/me, plus the public
/// GET /api/providers and GET /api/providers/{id} search/detail endpoints.
class ProviderProfileApi {
  const ProviderProfileApi(this._dio);

  final Dio _dio;

  /// [categoryId] is optional - omitting it browses every approved
  /// provider; passing one narrows to providers offering something in it.
  Future<List<ProviderProfile>> browseProviders({String? categoryId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/providers',
      queryParameters: categoryId != null ? {'categoryId': categoryId} : null,
    );
    return response.data!.map((e) => ProviderProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProviderDetail> getProviderDetail(String providerId) async {
    final response = await _dio.get<Map<String, dynamic>>('/providers/$providerId');
    return ProviderDetail.fromJson(response.data!);
  }

  /// Throws a DioException with statusCode 404 if the provider hasn't
  /// created a profile yet - ProviderProfileRepository is what turns that
  /// specific case into a plain `null` instead of an error.
  Future<ProviderProfile> getMyProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/providers/me');
    return ProviderProfile.fromJson(response.data!);
  }

  Future<ProviderProfile> upsertMyProfile({
    required String businessName,
    String? description,
    String? location,
    String? profileImageUrl,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/providers/me',
      data: {
        'businessName': businessName,
        'description': description,
        'location': location,
        'profileImageUrl': profileImageUrl,
      },
    );
    return ProviderProfile.fromJson(response.data!);
  }
}
