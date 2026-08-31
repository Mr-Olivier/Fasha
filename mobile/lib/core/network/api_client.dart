import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_session_storage.dart';

/// Builds the single Dio instance the whole app makes API calls through.
///
/// Every request automatically gets an "Authorization: Bearer" header added
/// (when a session exists) via the interceptor below - individual API
/// classes (AuthApi, and every future *Api class) never have to think
/// about auth headers themselves.
class ApiClient {
  ApiClient(AuthSessionStorage sessionStorage) : dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await sessionStorage.read();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.token}';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;

  /// The backend (see README.md section 19) runs on localhost:8081 during
  /// development.
  ///
  /// Every platform this app runs on treats "localhost" as itself, EXCEPT
  /// Android (both the emulator and a real device) - to Android,
  /// "localhost" is the phone/emulator, a completely different machine
  /// from your dev machine's point of view. Rather than special-casing the
  /// emulator's old 10.0.2.2 alias (which doesn't exist on a real device
  /// at all), this app requires running:
  ///
  ///   adb reverse tcp:8081 tcp:8081
  ///
  /// once after connecting - for the emulator OR a real device over USB -
  /// which forwards Android's own "localhost:8081" straight to this exact
  /// backend. That makes the SAME url work everywhere, with no LAN IP to
  /// hunt down and no emulator-only special case to maintain.
  static String get _baseUrl => 'http://localhost:8081/api';

  /// Same host as [_baseUrl], but without the "/api" prefix - avatar URLs
  /// (e.g. "/uploads/avatars/xyz.jpg") come from StaticResourceConfig on
  /// the backend, which serves them OUTSIDE the "/api" REST namespace.
  /// ProfileScreen prepends this to build a full, loadable image URL.
  static String get mediaBaseUrl => _baseUrl.replaceFirst('/api', '');
}

/// Shared by every feature's *Api class, so the whole app makes requests
/// through the same Dio instance (and therefore the same auth interceptor)
/// instead of each feature quietly building its own.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(authSessionStorageProvider)),
);
