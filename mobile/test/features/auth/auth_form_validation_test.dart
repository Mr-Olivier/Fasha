import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fasha/features/auth/data/auth_session_storage.dart';
import 'package:fasha/features/auth/domain/auth_user.dart';
import 'package:fasha/features/auth/presentation/login_screen.dart';
import 'package:fasha/features/auth/presentation/register_screen.dart';

/// A fully in-memory stand-in for AuthSessionStorage. `implements` only
/// requires covering AuthSessionStorage's PUBLIC members (save/read/clear) -
/// its private fields aren't part of the contract - so this is a small,
/// honest fake, not a partial one.
///
/// Without this, AuthController.build() (which every screen below triggers
/// just by being watched) would hit the real flutter_secure_storage plugin,
/// which has no native implementation in a plain widget test and would
/// throw a MissingPluginException.
class _FakeAuthSessionStorage implements AuthSessionStorage {
  AuthUser? _cached;

  @override
  Future<AuthUser?> read() async => _cached;

  @override
  Future<void> save(AuthUser user) async => _cached = user;

  @override
  Future<void> clear() async => _cached = null;
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authSessionStorageProvider.overrideWithValue(_FakeAuthSessionStorage())],
      child: MaterialApp(home: screen),
    ),
  );
  // Lets AuthController.build()'s restoreSession() future resolve, so the
  // submit button isn't stuck disabled in the initial "loading" state.
  await tester.pumpAndSettle();
}

void main() {
  group('LoginScreen validation', () {
    testWidgets('shows errors when submitted empty', (tester) async {
      await _pumpScreen(tester, const LoginScreen());

      // find.text('Log in') would also match the AppBar title, so we target
      // the button specifically.
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows an error for a malformed email', (tester) async {
      await _pumpScreen(tester, const LoginScreen());

      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });

  group('RegisterScreen validation', () {
    testWidgets('shows an error for a password shorter than 8 characters', (tester) async {
      await _pumpScreen(tester, const RegisterScreen());

      // Step 1 (role choice) - Customer is pre-selected, so Continue moves
      // straight to step 2 without picking anything.
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 2 (details) field order: name, phone, email, password.
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice Uwase');
      await tester.enterText(find.byType(TextFormField).at(2), 'alice@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'short');
      // The submit button stays disabled until Terms is checked.
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(find.text('Use at least 8 characters'), findsOneWidget);
    });
  });
}
