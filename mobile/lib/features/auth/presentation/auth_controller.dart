import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/auth_session_storage.dart';
import '../domain/auth_user.dart';
import '../domain/user_role.dart';

// --- Dependency wiring ---
// Each provider below builds exactly one class, using whatever it depends
// on from the provider above it. Riverpod only creates each object once
// and reuses it everywhere it's read - this is what makes AuthRepository
// a genuine singleton without a manual service locator or global variable.

final _secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final authSessionStorageProvider = Provider<AuthSessionStorage>(
  (ref) => AuthSessionStorage(ref.watch(_secureStorageProvider)),
);

final _apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(authSessionStorageProvider)),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(_apiClientProvider).dio),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authApiProvider), ref.watch(authSessionStorageProvider)),
);

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

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
