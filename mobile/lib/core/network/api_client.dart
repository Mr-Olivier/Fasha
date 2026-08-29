import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_session_storage.dart';

/// Builds the single Dio instance the whole app makes API calls through.
///
/// Every request automatically gets "Authorization: Bearer <token>" added
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
  /// development. An Android EMULATOR can't reach the host machine's
  /// "localhost" directly - 10.0.2.2 is the emulator's special alias for
  /// that. We use `defaultTargetPlatform` (not dart:io's Platform) because
  /// dart:io doesn't exist on web at all; defaultTargetPlatform is Flutter's
  /// own cross-platform-safe way to ask "what platform is this?".
  static String get _baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081/api';
    }
    return 'http://localhost:8081/api';
  }
}
