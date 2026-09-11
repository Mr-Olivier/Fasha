import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_categories_screen.dart';
import '../../features/admin/presentation/admin_customers_screen.dart';
import '../../features/admin/presentation/admin_providers_screen.dart';
import '../../features/admin/presentation/audit_log_screen.dart';
import '../../features/admin/presentation/category_form_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/bookings/domain/booking.dart';
import '../../features/bookings/presentation/incoming_requests_screen.dart';
import '../../features/bookings/presentation/my_bookings_screen.dart';
import '../../features/bookings/presentation/request_booking_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/providers/presentation/provider_detail_screen.dart';
import '../../features/providers/presentation/provider_list_screen.dart';
import '../../features/providers/presentation/provider_profile_screen.dart';
import '../../features/reviews/presentation/write_review_screen.dart';
import '../../features/services/domain/category.dart';
import '../../features/services/domain/service_listing.dart';
import '../../features/services/presentation/all_categories_screen.dart';
import '../../features/services/presentation/my_services_screen.dart';
import '../../features/services/presentation/service_form_screen.dart';
import '../../features/splash/presentation/splash_controller.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_shell.dart';

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
    ref.listen(splashMinimumDurationProvider, (previous, next) => notifyListeners());
    ref.listen(onboardingCompletedProvider, (previous, next) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final splashTimer = ref.read(splashMinimumDurationProvider);
      final onboardingState = ref.read(onboardingCompletedProvider);
      final isOnSplash = state.matchedLocation == '/splash';

      // Three independent reasons to stay on the splash screen: still
      // restoring the session from storage (see AuthController.build), the
      // fixed minimum splash duration hasn't elapsed yet (see
      // splashMinimumDurationProvider), or we don't know yet whether this
      // device has ever finished onboarding - whichever takes longest
      // wins, rather than bouncing forward the instant one settles.
      if (authState.isLoading || splashTimer.isLoading || onboardingState.isLoading) {
        return isOnSplash ? null : '/splash';
      }

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      // Forgot/reset-password are reachable without being logged in, same
      // as login/register - they're how a locked-out user gets back IN.
      const authScreens = {'/login', '/register', '/forgot-password', '/reset-password'};
      final isOnAuthScreen = authScreens.contains(state.matchedLocation);
      final isOnVerifyEmail = state.matchedLocation == '/verify-email';

      if (isLoggedIn) {
        // A freshly registered account is logged in immediately (see
        // AuthService.register's doc comment on the backend) but can't go
        // anywhere else until its email is verified - VerifyEmailScreen's
        // own "Log out" button is the only way out of this state besides
        // actually verifying.
        if (!user.emailVerified) return isOnVerifyEmail ? null : '/verify-email';
        return (isOnAuthScreen || isOnSplash || isOnVerifyEmail) ? '/home' : null;
      }

      final hasSeenOnboarding = onboardingState.valueOrNull ?? false;
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // Logged-out and never finished onboarding on this device (see
      // onboardingCompletedProvider) - shown exactly once, before /login
      // is ever reachable at all.
      if (!hasSeenOnboarding) return isOnOnboarding ? null : '/onboarding';
      // Already seen it - don't let a back-button press land here again.
      if (isOnOnboarding) return '/login';
      return isOnAuthScreen ? null : '/login'; // covers isOnSplash too, since it's not an auth screen
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        // `extra` carries the email from ForgotPasswordScreen, or null
        // when reached some other way (e.g. a bookmarked link).
        builder: (context, state) => ResetPasswordScreen(prefilledEmail: state.extra as String?),
      ),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      // Branch order/count is fixed - it's what AppShell's tuples
      // (_home/_providers/_customers/_categories/_profile) index into by
      // position, regardless of which of these a given role actually shows
      // as a visible tab. See AppShell's doc comment for the full reasoning.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/providers', builder: (context, state) => const AdminProvidersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/customers', builder: (context, state) => const AdminCustomersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoriesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/profile/change-password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/provider-profile', builder: (context, state) => const ProviderProfileScreen()),
      GoRoute(path: '/my-services', builder: (context, state) => const MyServicesScreen()),
      GoRoute(
        path: '/my-services/form',
        // `extra` carries the ServiceListing being edited, or null when
        // adding a new one - see ServiceFormScreen's doc comment for why.
        builder: (context, state) => ServiceFormScreen(existing: state.extra as ServiceListing?),
      ),
      GoRoute(path: '/categories', builder: (context, state) => const AllCategoriesScreen()),
      GoRoute(
        path: '/providers',
        // Real query params (not `extra`) so this URL survives a browser
        // refresh - tapped from HomeScreen's category grid.
        builder: (context, state) => ProviderListScreen(
          categoryId: state.uri.queryParameters['categoryId'],
          categoryName: state.uri.queryParameters['categoryName'],
        ),
      ),
      GoRoute(
        path: '/providers/:id',
        builder: (context, state) => ProviderDetailScreen(providerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/request-booking',
        // `extra` carries the ServiceListing being requested - see
        // ProviderDetailScreen's service list onTap.
        builder: (context, state) => RequestBookingScreen(service: state.extra as ServiceListing),
      ),
      GoRoute(path: '/my-bookings', builder: (context, state) => const MyBookingsScreen()),
      GoRoute(
        path: '/chat',
        // `extra` carries the ChatScreenArgs (bookingId + other party's
        // name) - see ChatEntryRow's onTap.
        builder: (context, state) => ChatScreen(args: state.extra as ChatScreenArgs),
      ),
      GoRoute(
        path: '/admin/categories/form',
        // `extra` carries the Category being edited, or null when adding a
        // new one - see CategoryFormScreen's doc comment for why.
        builder: (context, state) => CategoryFormScreen(existing: state.extra as Category?),
      ),
      GoRoute(path: '/admin/audit-log', builder: (context, state) => const AuditLogScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/incoming-requests', builder: (context, state) => const IncomingRequestsScreen()),
      GoRoute(
        path: '/write-review',
        // `extra` carries the COMPLETED Booking being reviewed - see
        // MyBookingsScreen's "Leave a review" button.
        builder: (context, state) => WriteReviewScreen(booking: state.extra as Booking),
      ),
    ],
  );
});
