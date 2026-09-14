import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/provider_detail.dart';
import '../domain/provider_profile.dart';

/// Raw HTTP calls to GET/PUT /api/providers/me, plus the public
/// GET /api/providers and GET /api/providers/{id} search/detail endpoints.
class ProviderProfileApi {
  const ProviderProfileApi(this._dio);

  final Dio _dio;

  /// All filters are optional and combine (the backend ANDs them, not ORs)
  /// - omitting all of them browses every approved provider. [minRating]
  /// and [maxPrice] back the Filters sheet's rating chips/price slider.
  Future<List<ProviderProfile>> browseProviders({
    String? categoryId,
    String? search,
    double? minRating,
    double? maxPrice,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/providers',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (minRating != null) 'minRating': minRating,
        if (maxPrice != null) 'maxPrice': maxPrice,
      },
    );
    return response.data!.map((e) => ProviderProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> favorite(String providerId) => _dio.post<void>('/providers/$providerId/favorite');

  Future<void> unfavorite(String providerId) => _dio.delete<void>('/providers/$providerId/favorite');

  Future<List<ProviderProfile>> listFavorites() async {
    final response = await _dio.get<List<dynamic>>('/favorites');
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
    String? categoryId,
    int? yearsExperience,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/providers/me',
      data: {
        'businessName': businessName,
        'description': description,
        'location': location,
        'profileImageUrl': profileImageUrl,
        'categoryId': categoryId,
        'yearsExperience': yearsExperience,
      },
    );
    return ProviderProfile.fromJson(response.data!);
  }

  Future<ProviderProfile> uploadPhoto(XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    final response = await _dio.post<Map<String, dynamic>>('/providers/me/photo', data: formData);
    return ProviderProfile.fromJson(response.data!);
  }
}
