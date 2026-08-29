import 'package:dio/dio.dart';

import '../domain/auth_user.dart';
import '../domain/user_role.dart';

/// Raw HTTP calls to POST /api/auth/register, /login, and /logout.
///
/// This class only knows how to talk to those two endpoints - it doesn't
/// catch errors or touch storage. AuthRepository is the layer that adds
/// error handling and persistence on top; keeping this split means each
/// class has exactly one job.
class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<AuthUser> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.toWire(),
      },
    );
    return AuthUser.fromJson(response.data!);
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthUser.fromJson(response.data!);
  }

  /// No body, no return value - the "Authorization: Bearer" header is
  /// enough for the backend to know which token to revoke (added
  /// automatically by ApiClient's interceptor, same as every other call).
  Future<void> logout() => _dio.post<void>('/auth/logout');
}
