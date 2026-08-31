import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/user_account.dart';
import 'user_api.dart';

/// Adds error handling on top of UserApi, turning Dio's low-level
/// exceptions into the app's own ApiException - same split as
/// AuthRepository/AuthApi, for the same reason (see that class's doc
/// comment).
class UserRepository {
  const UserRepository(this._api);

  final UserApi _api;

  Future<UserAccount> getMe() async {
    try {
      return await _api.getMe();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserAccount> updateProfile({required String name, String? phone}) async {
    try {
      return await _api.updateProfile(name: name, phone: phone);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _api.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserAccount> uploadAvatar(XFile image) async {
    try {
      return await _api.uploadAvatar(image);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
