import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_user.dart';
import '../domain/password_reset_result.dart';
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

  /// Logs out both server-side (revokes the token, so it stops working
  /// immediately instead of just sitting valid until it expires) and
  /// locally (clears the cached session so the app itself forgets you).
  ///
  /// The API call is best-effort: if it fails (no internet, server down),
  /// we still clear local storage. A user tapping "log out" expects to be
  /// logged out of THIS APP regardless of network state - the token simply
  /// stays valid server-side until its normal expiry in that edge case,
  /// which is an acceptable trade-off rather than trapping the user in a
  /// "can't log out" state.
  Future<void> logout() async {
    try {
      await _api.logout();
    } on DioException {
      // Deliberately ignored - see doc comment above.
    }
    await _storage.clear();
  }

  /// Called once when the app starts, so a previously logged-in user
  /// doesn't have to log in again every time they reopen the app.
  Future<AuthUser?> restoreSession() => _storage.read();

  /// Overwrites the cached session with an already-updated [user] - no
  /// network call here, just persistence. Used by
  /// AuthController.applyAccountUpdate after a profile edit succeeds, so
  /// the edited name/phone/avatar survive an app restart too.
  Future<void> persistUser(AuthUser user) => _storage.save(user);

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    try {
      return await _api.forgotPassword(email: email);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    try {
      await _api.resetPassword(email: email, code: code, newPassword: newPassword);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> verifyEmail({required String code}) async {
    try {
      await _api.verifyEmail(code: code);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> resendVerification() async {
    try {
      await _api.resendVerification();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
