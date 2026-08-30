import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../domain/category.dart';
import 'category_controller.dart';
import 'service_listing_controller.dart';

class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(serviceListingControllerProvider);
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/my-services/form'),
        child: const Icon(Icons.add),
      ),
      body: servicesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiException ? error.message : 'Could not load your services.'),
        ),
        data: (services) {
          if (services.isEmpty) {
            return const Center(child: Text('No services yet. Tap + to add one.'));
          }

          // A best-effort lookup: while categories are still loading (or if
          // they fail), we fall back to showing nothing for the category
          // label rather than blocking the whole services list on it - the
          // service list itself doesn't depend on categories being loaded.
          final categoriesById = <String, Category>{
            for (final category in categoriesState.valueOrNull ?? const <Category>[]) category.id: category,
          };

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final categoryName = categoriesById[service.categoryId]?.name;
              return ListTile(
                title: Text(service.name),
                subtitle: Text(categoryName == null ? 'RWF ${service.price}' : '$categoryName · RWF ${service.price}'),
                onTap: () => context.push('/my-services/form', extra: service),
              );
            },
          );
        },
      ),
    );
  }
}
