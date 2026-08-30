import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kazilink_rwanda/features/auth/data/auth_session_storage.dart';
import 'package:kazilink_rwanda/features/auth/domain/auth_user.dart';
import 'package:kazilink_rwanda/main.dart';

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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionStorageProvider.overrideWithValue(_FakeAuthSessionStorage())],
        child: const KaziLinkApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
  });
}
