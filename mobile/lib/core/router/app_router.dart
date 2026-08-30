import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/providers/presentation/provider_profile_screen.dart';

/// Bridges Riverpod state to GoRouter's `refreshListenable`.
///
/// GoRouter needs a Listenable to know "something changed, re-run my
/// redirect logic" - it doesn't understand Riverpod providers directly.
/// Without this class, the tempting shortcut is to build a brand new
/// GoRouter every time auth state changes (e.g. inside a Provider that
/// `ref.watch`es authControllerProvider) - but that recreates the entire
/// router, silently resetting navigation history. This keeps ONE GoRouter
/// alive for the app's lifetime and just tells it "go re-check redirect".
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      // Still restoring the session from storage (see AuthController.build) -
      // don't redirect anywhere yet, or we'd bounce a logged-in user to
      // /login for a split second before we actually know.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isOnAuthScreen) return '/login';
      if (isLoggedIn && isOnAuthScreen) return '/home';
      return null; // no redirect needed
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/provider-profile', builder: (context, state) => const ProviderProfileScreen()),
    ],
  );
});
