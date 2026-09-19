import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fasha/features/auth/data/auth_session_storage.dart';
import 'package:fasha/features/auth/domain/auth_user.dart';
import 'package:fasha/main.dart';

/// See the matching fake in test/features/auth/auth_form_validation_test.dart
/// for why this exists: the real AuthSessionStorage needs the
/// flutter_secure_storage plugin, which isn't available in a plain
/// widget test's environment.
class _FakeAuthSessionStorage implements AuthSessionStorage {
  @override
  Future<AuthUser?> read() async => null;

  @override
  Future<void> save(AuthUser user) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('App boots logged-out and lands on the login screen', (WidgetTester tester) async {
    // onboardingCompletedProvider (features/onboarding) reads
    // SharedPreferences - without this, getInstance() never resolves in a
    // plain widget test (no real platform channel to answer it), which
    // left the router's redirect logic stuck thinking onboarding state was
    // still loading forever, keeping the app on SplashScreen no matter how
    // long the test waited. This was the actual cause of this test's
    // "flaky pumpAndSettle timeout" - not flaky at all, just always broken
    // for this specific reason. Marking onboarding already-seen here is
    // also what makes "lands on the login screen" (not /onboarding) the
    // correct expectation.
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionStorageProvider.overrideWithValue(_FakeAuthSessionStorage())],
        child: const FashaApp(),
      ),
    );

    // SplashScreen shows an indeterminate CircularProgressIndicator the
    // whole time it's up - pumpAndSettle() can never settle while one is
    // on screen (its animation always has a frame scheduled, by design),
    // regardless of how much real/virtual time passes. Pump forward past
    // splashMinimumDurationProvider's fixed 5-second wait by hand instead,
    // which lets the router's redirect actually leave "/splash"; THEN
    // settle once we've landed on a screen with no perpetual animation.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
  });
}
