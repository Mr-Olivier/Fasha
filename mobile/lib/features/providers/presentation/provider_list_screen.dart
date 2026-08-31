import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'provider_browse_controller.dart';

/// Customer-facing: approved providers offering something in one category
/// (tapped from HomeScreen's category grid). [categoryId] is null only if
/// this screen is somehow reached without one, in which case it falls back
/// to showing every approved provider rather than an empty/broken screen.
class ProviderListScreen extends ConsumerWidget {
  const ProviderListScreen({super.key, this.categoryId, this.categoryName});

  final String? categoryId;
  final String? categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersState = ref.watch(providerBrowseProvider(categoryId));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(categoryName ?? 'Providers')),
      body: providersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load providers.')),
        data: (providers) {
          if (providers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No approved providers offer this yet. Check back soon.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      provider.businessName.isNotEmpty ? provider.businessName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(provider.businessName),
                  subtitle: Text(provider.location ?? 'Location not specified'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/providers/${provider.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
