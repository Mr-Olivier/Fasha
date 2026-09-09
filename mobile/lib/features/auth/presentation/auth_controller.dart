import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/auth_session_storage.dart';
import '../data/google_auth_service.dart';
import '../domain/auth_user.dart';
import '../domain/user_role.dart';

// --- Dependency wiring ---
// Each provider below builds exactly one class, using whatever it depends
// on from the provider above it. Riverpod only creates each object once
// and reuses it everywhere it's read - this is what makes AuthRepository
// a genuine singleton without a manual service locator or global variable.
//
// authSessionStorageProvider lives in auth_session_storage.dart and
// apiClientProvider lives in api_client.dart (colocated with the classes
// they build) - every other feature's *Api class reuses apiClientProvider
// too, so the whole app shares one Dio instance and one auth interceptor.

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider).dio),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authApiProvider), ref.watch(authSessionStorageProvider)),
);

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());

/// The app's single source of truth for "who is logged in right now".
///
/// AsyncNotifier of AuthUser? means our state is always one of these:
///  - AsyncLoading: we don't know yet (checking storage, or a request is in flight)
///  - AsyncData(null): logged out
///  - AsyncData(user): logged in as `user`
///  - AsyncError(e): the last register/login attempt failed with error `e`
/// Every screen that cares about auth (the router, HomeScreen, ...) just
/// watches this one provider instead of tracking loading/error booleans by hand.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    // Runs once when the app starts: try to restore a previously saved
    // session so the user isn't forced to log in every single time.
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    // AsyncValue.guard runs the future and automatically wraps the result as
    // AsyncData on success or AsyncError on any thrown exception - we never
    // need a manual try/catch here.
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            phone: phone,
            password: password,
            role: role,
          ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  /// Runs Google's account picker, then signs in (or signs up, for a
  /// first-time Google account) with the ID token it returns. Leaves state
  /// untouched if the user closes the picker without choosing an account -
  /// that's not an error, just "never mind", so no loading/error state
  /// should flash for it.
  ///
  /// [role] is only used by the backend the first time this Google account
  /// is seen; ignored for an existing account, whose role is already set.
  Future<void> loginWithGoogle({UserRole? role}) async {
    final String? idToken;
    try {
      idToken = await ref.read(googleAuthServiceProvider).signInAndGetIdToken();
    } catch (error, stackTrace) {
      // Surfaced the same way a failed login/register would be (picked up
      // by ref.listen in the screen) - covers "not configured yet" and any
      // failure from the Google SDK itself (network, misconfigured
      // console credentials, ...).
      state = AsyncValue.error(error, stackTrace);
      return;
    }
    final resolvedIdToken = idToken;
    if (resolvedIdToken == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).googleAuth(idToken: resolvedIdToken, role: role),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    // Best-effort, like the repository's own server-side revoke - clears
    // Google's cached account choice so the next "Continue with Google"
    // shows the picker again instead of silently reusing this session.
    unawaited(ref.read(googleAuthServiceProvider).signOut());
    state = const AsyncValue.data(null);
  }

  /// Folds a fresh account snapshot (from GET/PATCH /api/users/me or the
  /// avatar upload endpoint - see UserProfileController) back into the
  /// cached, logged-in user, so every screen watching this controller
  /// (HomeScreen's greeting, ProfileScreen, ...) reflects an edit
  /// immediately instead of only after the next login.
  ///
  /// Takes plain fields rather than a UserAccount object on purpose - this
  /// class belongs to the auth feature and shouldn't need to import the
  /// profile feature's domain types just to accept an update.
  void applyAccountUpdate({required String name, String? phone, String? profileImageUrl}) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AuthUser(
      token: current.token,
      userId: current.userId,
      name: name,
      email: current.email,
      role: current.role,
      emailVerified: current.emailVerified,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
    state = AsyncValue.data(updated);
    ref.read(authRepositoryProvider).persistUser(updated);
  }

  /// Flips the cached session's emailVerified to true after
  /// VerifyEmailController.verify() succeeds - VerifyEmailScreen's cue,
  /// same pattern as applyAccountUpdate, to leave that screen since
  /// app_router.dart's redirect no longer forces the user back onto it.
  void applyEmailVerified() {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AuthUser(
      token: current.token,
      userId: current.userId,
      name: current.name,
      email: current.email,
      role: current.role,
      emailVerified: true,
      phone: current.phone,
      profileImageUrl: current.profileImageUrl,
    );
    state = AsyncValue.data(updated);
    ref.read(authRepositoryProvider).persistUser(updated);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
