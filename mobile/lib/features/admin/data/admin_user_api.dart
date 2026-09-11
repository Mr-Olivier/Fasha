import 'package:dio/dio.dart';

import '../../auth/domain/user_role.dart';
import '../domain/account_status.dart';
import '../domain/admin_user.dart';

/// Raw HTTP calls to /api/admin/users - admin-only, enforced server-side by
/// @PreAuthorize("hasRole('ADMIN')") on AdminUserController. Shared by both
/// the Customers and Providers admin screens (filtered by [role]) since
/// "manage an account" means the same thing regardless of which role it
/// belongs to.
class AdminUserApi {
  const AdminUserApi(this._dio);

  final Dio _dio;

  Future<List<AdminUser>> list({UserRole? role}) async {
    final response = await _dio.get<List<dynamic>>(
      '/admin/users',
      queryParameters: role != null ? {'role': role.toWire()} : null,
    );
    return response.data!.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminUser> setStatus({required String userId, required AccountStatus status}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/users/$userId/status',
      data: {'status': status.toWire()},
    );
    return AdminUser.fromJson(response.data!);
  }

  Future<void> delete(String userId) {
    return _dio.delete('/admin/users/$userId');
  }
}
