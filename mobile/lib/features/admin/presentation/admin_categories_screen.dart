import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../services/domain/category.dart';
import '../../services/presentation/category_icon_badge.dart';
import '../domain/admin_category.dart';
import 'admin_category_controller.dart';

/// Admin's category management screen - matches the "Manage categories"
/// screen from the project's design reference (E3): counts + a hide/show
/// toggle per row instead of bare edit/delete icons. Same list-with-actions
/// shape as AdminProvidersScreen; editing (including delete - see
/// CategoryFormScreen) lives one tap away on CategoryFormScreen rather than
/// crowding this list with more icons than the design shows.
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  // Tracks which row's visibility toggle is in flight, so only THAT row
  // shows a spinner - adminCategoryControllerProvider only holds one
  // in-flight mutation at a time, not which category it belongs to.
  String? _busyCategoryId;

  Future<void> _toggleVisibility(AdminCategory category) {
    _busyCategoryId = category.id;
    return ref
        .read(adminCategoryControllerProvider.notifier)
        .setVisibility(categoryId: category.id, active: !category.active);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(adminCategoryControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(adminCategoryControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        _busyCategoryId = null;
        AppToast.apiError(context, error);
        return;
      }
      if (next.hasValue && previous?.isLoading == true && _busyCategoryId != null) {
        _busyCategoryId = null;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/categories/form'),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load categories.')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No categories yet. Tap "Add category" to create the first one.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          final hiddenCount = categories.where((c) => !c.active).length;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminCategoryControllerProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.gutter,
                AppSpacing.gutter,
                AppSpacing.gutter + 72, // clears the FAB
              ),
              children: [
                Text(
                  '${categories.length} total'
                  '${hiddenCount > 0 ? ' · $hiddenCount hidden' : ''}',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final category in categories) ...[
                  _CategoryRow(
                    category: category,
                    isBusy: categoriesState.isLoading && _busyCategoryId == category.id,
                    onToggle: () => _toggleVisibility(category),
                    onTap: () => context.push(
                      '/admin/categories/form',
                      extra: Category(
                        id: category.id,
                        name: category.name,
                        description: category.description,
                        imageUrl: category.imageUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.isBusy, required this.onToggle, required this.onTap});

  final AdminCategory category;
  final bool isBusy;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final active = category.active;

    final subtitle = active
        ? '${category.providerCount} provider${category.providerCount == 1 ? '' : 's'}'
            ' · ${category.bookingCount} booking${category.bookingCount == 1 ? '' : 's'}'
        : 'Hidden · ${category.providerCount} provider${category.providerCount == 1 ? '' : 's'}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Opacity(
                opacity: active ? 1 : 0.45,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CategoryIconBadge(
                    category: Category(id: category.id, name: category.name, imageUrl: category.imageUrl),
                    iconSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: active ? null : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isBusy)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                Switch(value: active, onChanged: (_) => onToggle()),
            ],
          ),
        ),
      ),
    );
  }
}
