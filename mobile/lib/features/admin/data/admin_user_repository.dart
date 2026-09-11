import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/user_role.dart';
import '../domain/account_status.dart';
import '../domain/admin_user.dart';
import 'admin_user_api.dart';

class AdminUserRepository {
  const AdminUserRepository(this._api);

  final AdminUserApi _api;

  Future<List<AdminUser>> list({UserRole? role}) async {
    try {
      return await _api.list(role: role);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminUser> setStatus({required String userId, required AccountStatus status}) async {
    try {
      return await _api.setStatus(userId: userId, status: status);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String userId) async {
    try {
      await _api.delete(userId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
