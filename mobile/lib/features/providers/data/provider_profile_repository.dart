import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/provider_profile.dart';
import 'provider_profile_api.dart';

class ProviderProfileRepository {
  const ProviderProfileRepository(this._api);

  final ProviderProfileApi _api;

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
  }) async {
    try {
      return await _api.upsertMyProfile(
        businessName: businessName,
        description: description,
        location: location,
        profileImageUrl: profileImageUrl,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
