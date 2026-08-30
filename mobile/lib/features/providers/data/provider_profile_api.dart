import 'package:dio/dio.dart';

import '../domain/provider_profile.dart';

/// Raw HTTP calls to GET/PUT /api/providers/me.
class ProviderProfileApi {
  const ProviderProfileApi(this._dio);

  final Dio _dio;

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
