import 'package:dio/dio.dart';

import '../domain/auth_user.dart';
import '../domain/password_reset_result.dart';
import '../domain/user_role.dart';

/// Raw HTTP calls to POST /api/auth/register, /login, /logout,
/// /forgot-password, /reset-password, /verify-email, and
/// /resend-verification.
///
/// This class only knows how to talk to those endpoints - it doesn't catch
/// errors or touch storage. AuthRepository is the layer that adds error
/// handling and persistence on top; keeping this split means each class
/// has exactly one job.
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

  /// Always succeeds (even for an email that doesn't exist - see the
  /// backend's own doc comment on AuthService.forgotPassword for why).
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return ForgotPasswordResult.fromJson(response.data!);
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) {
    return _dio.post<void>(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  /// The "Authorization: Bearer" header (from register()'s own JWT) is
  /// enough to identify which account's code this is - same reasoning as
  /// logout() needing no body of its own.
  Future<void> verifyEmail({required String code}) {
    return _dio.post<void>('/auth/verify-email', data: {'code': code});
  }

  Future<void> resendVerification() => _dio.post<void>('/auth/resend-verification');
}
