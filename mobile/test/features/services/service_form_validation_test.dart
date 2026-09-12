import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kazilink_rwanda/features/services/data/category_repository.dart';
import 'package:kazilink_rwanda/features/services/data/service_listing_repository.dart';
import 'package:kazilink_rwanda/features/services/domain/category.dart';
import 'package:kazilink_rwanda/features/services/domain/service_duration.dart';
import 'package:kazilink_rwanda/features/services/domain/service_listing.dart';
import 'package:kazilink_rwanda/features/services/presentation/category_controller.dart';
import 'package:kazilink_rwanda/features/services/presentation/service_form_screen.dart';
import 'package:kazilink_rwanda/features/services/presentation/service_listing_controller.dart';

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchCategories() async => const [Category(id: 'cat-1', name: 'Plumber')];
}

class _FakeServiceListingRepository implements ServiceListingRepository {
  @override
  Future<List<ServiceListing>> listMyServices() async => [];

  @override
  Future<ServiceListing> addService({
    required String categoryId,
    required String name,
    String? description,
    required double price,
    required ServiceDuration duration,
    required bool visible,
  }) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<ServiceListing> updateService({
    required String serviceId,
    required String categoryId,
    required String name,
    String? description,
    required double price,
    required ServiceDuration duration,
    required bool visible,
  }) {
    throw UnimplementedError('not exercised by this test');
  }

  @override
  Future<ServiceListing> setVisibility({required String serviceId, required bool visible}) {
    throw UnimplementedError('not exercised by this test');
  }
}

void main() {
  testWidgets('shows errors when submitted with nothing filled in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
          serviceListingRepositoryProvider.overrideWithValue(_FakeServiceListingRepository()),
        ],
        child: const MaterialApp(home: ServiceFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The form grew taller once duration chips + the visibility toggle were
    // added, so "Add service" no longer fits the test viewport without
    // scrolling to it first.
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add service'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add service'));
    await tester.pump();

    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Price is required'), findsOneWidget);
  });
}
