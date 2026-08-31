import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/user_account.dart';

/// Raw HTTP calls to GET/PATCH /api/users/me, PUT /api/users/me/password,
/// and POST /api/users/me/avatar.
///
/// Every request here needs a valid JWT, added automatically by
/// ApiClient's interceptor (same as every other *Api class) - none of
/// these routes are in the backend's permitAll list.
class UserApi {
  const UserApi(this._dio);

  final Dio _dio;

  Future<UserAccount> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserAccount.fromJson(response.data!);
  }

  Future<UserAccount> updateProfile({required String name, String? phone}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/users/me',
      data: {'name': name, 'phone': phone},
    );
    return UserAccount.fromJson(response.data!);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    return _dio.put<void>(
      '/users/me/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  /// [image] comes from image_picker's XFile - reading it as bytes (rather
  /// than a dart:io File) works the same way on web and native, since web
  /// has no real filesystem path to hand Dio instead.
  Future<UserAccount> uploadAvatar(XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    final response = await _dio.post<Map<String, dynamic>>('/users/me/avatar', data: formData);
    return UserAccount.fromJson(response.data!);
  }
}
