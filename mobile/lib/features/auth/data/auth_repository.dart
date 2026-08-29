import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_user.dart';
import '../domain/user_role.dart';
import 'auth_api.dart';
import 'auth_session_storage.dart';

/// The single entry point the rest of the app (AuthController) talks to
/// for anything auth-related. It combines the network call (AuthApi) with
/// persistence (AuthSessionStorage) and turns Dio's low-level exceptions
/// into the app's own ApiException.
class AuthRepository {
  const AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final AuthSessionStorage _storage;

  Future<AuthUser> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      await _storage.save(user);
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final user = await _api.login(email: email, password: password);
      await _storage.save(user);
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() => _storage.clear();

  /// Called once when the app starts, so a previously logged-in user
  /// doesn't have to log in again every time they reopen the app.
  Future<AuthUser?> restoreSession() => _storage.read();
}
