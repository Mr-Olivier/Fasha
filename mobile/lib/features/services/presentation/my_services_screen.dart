import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../domain/category.dart';
import '../domain/service_listing.dart';
import 'category_controller.dart';
import 'category_icon_badge.dart';
import 'service_listing_controller.dart';

class MyServicesScreen extends ConsumerStatefulWidget {
  const MyServicesScreen({super.key});

  @override
  ConsumerState<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends ConsumerState<MyServicesScreen> {
  // null = the "All offerings" chip - filters by the service's own
  // categoryId, not some separate tag field the backend doesn't have.
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final servicesState = ref.watch(serviceListingControllerProvider);
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Fasha Pro', subtitle: 'My Services'),
      body: servicesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiException ? error.message : 'Could not load your services.'),
        ),
        data: (services) {
          final categoriesById = <String, Category>{
            for (final category in categoriesState.valueOrNull ?? const <Category>[]) category.id: category,
          };

          if (services.isEmpty) {
            return _EmptyState(onAdd: () => context.push('/my-services/form'));
          }

          // Only the categories this provider actually lists a service
          // under become filter chips - never the full category catalogue,
          // since a chip for a category with nothing to show would filter
          // to an empty list.
          final usedCategoryIds = services.map((s) => s.categoryId).toSet();
          final filterCategories = usedCategoryIds.map((id) => categoriesById[id]).whereType<Category>().toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (_categoryFilter != null && !usedCategoryIds.contains(_categoryFilter)) {
            // The service that made this filter valid was deleted/edited
            // away from that category since - fall back to "All" instead
            // of silently filtering to nothing.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _categoryFilter = null);
            });
          }

          final shown =
              _categoryFilter == null ? services : services.where((s) => s.categoryId == _categoryFilter).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              _Header(count: services.length, onAdd: () => context.push('/my-services/form')),
              const SizedBox(height: AppSpacing.gutter),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All offerings (${services.length})'),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                    for (final category in filterCategories) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: Text(category.name),
                        selected: _categoryFilter == category.id,
                        onSelected: (_) => setState(() => _categoryFilter = category.id),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              for (final service in shown) ...[
                _ServiceCard(service: service, category: categoriesById[service.categoryId]),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Service Listings', style: textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                'Manage rates, availability & dispatch settings',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Service'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 16)),
        ),
      ],
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service, required this.category});

  final ServiceListing service;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: service.visible ? 1 : 0.7,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () => context.push('/my-services/form', extra: service),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null) ...[
                      SizedBox(width: 40, height: 40, child: CategoryIconBadge(category: category!, iconSize: 20)),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (category != null)
                            Text(
                              category!.name,
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    _StatusChip(visible: service.visible),
                  ],
                ),
                if ((service.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    service.description!,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      'RWF ${service.price.toStringAsFixed(0)}',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      service.duration.label,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.gutter),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/my-services/form', extra: service),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Service'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Listed', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Switch(
                      value: service.visible,
                      onChanged: (value) => ref
                          .read(serviceListingControllerProvider.notifier)
                          .setVisibility(serviceId: service.id, visible: value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = visible ? colorScheme.tertiary : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        child: Text(
          visible ? 'Active & Listed' : 'Hidden',
          style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('No services yet', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add what you offer so customers can find and book you.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.gutter),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Service')),
          ],
        ),
      ),
    );
  }
}
