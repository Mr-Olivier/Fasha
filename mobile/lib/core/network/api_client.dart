import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_session_storage.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../config/app_config.dart';

/// Builds the single Dio instance the whole app makes API calls through.
///
/// Every request automatically gets an "Authorization: Bearer" header added
/// (when a session exists) via the interceptor below - individual API
/// classes (AuthApi, and every future *Api class) never have to think
/// about auth headers themselves.
///
/// Also handles the ACCESS token expiring mid-session: the backend now
/// issues short-lived access tokens (15 minutes - see
/// backend/application.yml's app.jwt.expiration-ms) paired with a
/// long-lived refresh token, rather than one 24-hour token. Rather than
/// making every screen in the app worry about "the server said 401, go
/// refresh and retry", that logic lives in exactly one place: this
/// interceptor's onError handler, silently and transparently.
class ApiClient {
  ApiClient(this._sessionStorage, this._ref) : dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await _sessionStorage.read();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.token}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.contains('/auth/');
          if (error.response?.statusCode != 401 || isAuthEndpoint) {
            handler.next(error);
            return;
          }

          try {
            final refreshed = await _refreshSession();
            final retryRequest = error.requestOptions..headers['Authorization'] = 'Bearer ${refreshed.token}';
            final response = await dio.fetch<dynamic>(retryRequest);
            handler.resolve(response);
          } on DioException {
            // The refresh token itself is dead too (expired, revoked by an
            // admin suspension, or reuse-detected - see
            // RefreshTokenService) - there's no way back into this session
            // short of logging in again.
            await _sessionStorage.clear();
            _ref.read(authControllerProvider.notifier).forceSignOut();
            handler.next(error);
          }
        },
      ),
    );
  }

  final AuthSessionStorage _sessionStorage;
  final Ref _ref;
  final Dio dio;

  /// Coalesces concurrent 401s (e.g. several requests firing at once right
  /// as the access token expires) into a SINGLE refresh call, instead of
  /// racing several rotations against each other - the backend's rotation
  /// invalidates a refresh token the moment it's used once, so a second
  /// concurrent call with that same now-stale token would fail outright
  /// and be treated as token theft (see RefreshTokenService.rotate).
  Future<AuthUser>? _refreshInFlight;

  Future<AuthUser> _refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<AuthUser> _doRefresh() async {
    final session = await _sessionStorage.read();
    if (session == null) {
      throw DioException(requestOptions: RequestOptions(path: '/auth/refresh'));
    }

    // A plain, interceptor-free Dio instance - refreshing must never itself
    // go through this class's onRequest/onError handlers (that would
    // attach the already-expired access token and risk recursing back into
    // this same refresh logic on failure).
    final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
    final response = await refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': session.refreshToken},
    );
    final refreshed = AuthUser.fromJson(response.data!);
    await _sessionStorage.save(refreshed);
    _ref.read(authControllerProvider.notifier).applyRefreshedSession(refreshed);
    return refreshed;
  }

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
  static String get _baseUrl => AppConfig.apiBaseUrl.isEmpty ? 'http://localhost:8081/api' : AppConfig.apiBaseUrl;

  /// The same base every *Api class's Dio calls resolve against, exposed
  /// for the rare caller that needs an absolute URL of its own rather than
  /// a Dio request - VideoPlayerController.networkUrl (an authenticated
  /// chat video) needs the full URL up front, not a path handed to Dio,
  /// since it does its own HTTP range-request streaming outside Dio
  /// entirely.
  static String get apiBaseUrl => _baseUrl;

  /// Same host as [_baseUrl], but without the "/api" prefix - avatar URLs
  /// (e.g. "/uploads/avatars/xyz.jpg") come from StaticResourceConfig on
  /// the backend, which serves them OUTSIDE the "/api" REST namespace.
  /// ProfileScreen prepends this to build a full, loadable image URL.
  static String get mediaBaseUrl => _baseUrl.replaceFirst('/api', '');

  /// Turns a [path] the backend returned (an avatar/category-icon/provider-photo
  /// URL) into one [NetworkImage] can actually load. AvatarStorageService
  /// now returns an already-absolute Cloudinary URL
  /// ("https://res.cloudinary.com/...") for anything uploaded after that
  /// switch, but older rows saved before it - or a local dev backend with
  /// no Cloudinary account configured - still return a relative path like
  /// "/uploads/avatars/xyz.jpg" that needs [mediaBaseUrl] prepended. Every
  /// caller must go through this rather than prepending mediaBaseUrl
  /// itself, or a Cloudinary URL would come out as
  /// "http://localhost:8081https://res.cloudinary.com/...".
  static String resolveMediaUrl(String path) => path.startsWith('http') ? path : '$mediaBaseUrl$path';

  /// Same host again, as a "ws://" URL with no path - ChatSocket appends
  /// "/ws/chat" itself. WebSocket connections use their own "ws"/"wss"
  /// scheme rather than "http"/"https", even though it's the same host and
  /// port as every REST call.
  static String get wsBaseUrl => mediaBaseUrl.replaceFirst('http', 'ws');
}

/// Shared by every feature's *Api class, so the whole app makes requests
/// through the same Dio instance (and therefore the same auth interceptor)
/// instead of each feature quietly building its own.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(authSessionStorageProvider), ref),
);
