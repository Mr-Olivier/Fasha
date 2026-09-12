import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/provider_detail.dart';
import '../domain/provider_profile.dart';
import 'provider_profile_api.dart';

class ProviderProfileRepository {
  const ProviderProfileRepository(this._api);

  final ProviderProfileApi _api;

  Future<List<ProviderProfile>> browseProviders({String? categoryId, String? search}) async {
    try {
      return await _api.browseProviders(categoryId: categoryId, search: search);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProviderDetail> getProviderDetail(String providerId) async {
    try {
      return await _api.getProviderDetail(providerId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// A 404 here means "you haven't created a profile yet" - a normal,
  /// expected state for a new provider, not an error. We turn that one
  /// specific status code into `null` so ProviderProfileController (and the
  /// screen) can tell "no profile yet" apart from "something went wrong"
  /// (which still throws ApiException, same as every other failure).
  Future<ProviderProfile?> fetchMyProfile() async {
    try {
      return await _api.getMyProfile();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProviderProfile> upsertMyProfile({
    required String businessName,
    String? description,
    String? location,
    String? profileImageUrl,
    String? categoryId,
    int? yearsExperience,
  }) async {
    try {
      return await _api.upsertMyProfile(
        businessName: businessName,
        description: description,
        location: location,
        profileImageUrl: profileImageUrl,
        categoryId: categoryId,
        yearsExperience: yearsExperience,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProviderProfile> uploadPhoto(XFile image) async {
    try {
      return await _api.uploadPhoto(image);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
