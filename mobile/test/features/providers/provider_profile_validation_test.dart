import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kazilink_rwanda/features/providers/data/provider_profile_repository.dart';
import 'package:kazilink_rwanda/features/providers/domain/provider_profile.dart';
import 'package:kazilink_rwanda/features/providers/presentation/provider_profile_controller.dart';
import 'package:kazilink_rwanda/features/providers/presentation/provider_profile_screen.dart';

/// Only fetchMyProfile is exercised by this test (the screen calls it once,
/// on build) - returning null means "no profile yet", the same as a fresh
/// provider account, so the screen renders its "create" form.
class _FakeProviderProfileRepository implements ProviderProfileRepository {
  @override
  Future<ProviderProfile?> fetchMyProfile() async => null;

  @override
  Future<ProviderProfile> upsertMyProfile({
    required String businessName,
    String? description,
    String? location,
    String? profileImageUrl,
  }) {
    throw UnimplementedError('not exercised by this test');
  }
}

void main() {
  testWidgets('shows an error when submitted with no business name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerProfileRepositoryProvider.overrideWithValue(_FakeProviderProfileRepository()),
        ],
        child: const MaterialApp(home: ProviderProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create profile'));
    await tester.pump();

    expect(find.text('Business name is required'), findsOneWidget);
  });
}
