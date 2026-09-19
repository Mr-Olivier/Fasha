import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fasha/features/providers/data/provider_profile_repository.dart';
import 'package:fasha/features/providers/domain/provider_detail.dart';
import 'package:fasha/features/providers/domain/provider_profile.dart';
import 'package:fasha/features/providers/presentation/provider_profile_controller.dart';
import 'package:fasha/features/providers/presentation/provider_profile_screen.dart';
import 'package:fasha/features/services/data/category_repository.dart';
import 'package:fasha/features/services/domain/category.dart';
import 'package:fasha/features/services/presentation/category_controller.dart';

/// ProviderProfileScreen now shows a category dropdown (D6) - without this
/// override, categoriesProvider would try a real network call that never
/// resolves in a widget test, hanging pumpAndSettle.
class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchCategories() async => const [Category(id: 'cat-1', name: 'Plumber')];
}

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
    String? categoryId,
    int? yearsExperience,
  }) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<ProviderProfile> uploadPhoto(XFile image) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<List<ProviderProfile>> browseProviders({String? categoryId, String? search, double? minRating, double? maxPrice}) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<ProviderDetail> getProviderDetail(String providerId) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<void> favorite(String providerId) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<void> unfavorite(String providerId) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<List<ProviderProfile>> listFavorites() {
    throw UnimplementedError('not exercised by this test');
  }
}

void main() {
  testWidgets('shows an error when submitted with no business name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerProfileRepositoryProvider.overrideWithValue(_FakeProviderProfileRepository()),
          categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
        ],
        child: const MaterialApp(home: ProviderProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Save moved into the AppBar (a TextButton, always labelled "Save") -
    // see provider_profile_screen.dart's D6 rework.
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    expect(find.text('Business name is required'), findsOneWidget);
  });
}
