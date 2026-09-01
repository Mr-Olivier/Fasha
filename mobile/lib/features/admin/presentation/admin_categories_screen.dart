import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../services/domain/category.dart';
import 'admin_category_controller.dart';

/// Admin's category CRUD screen - before this existed, the ONLY way to add
/// or rename a category was a developer running a direct database
/// INSERT/UPDATE (categories_table's own doc comment used to say as much).
/// Same list-with-actions shape as AdminProvidersScreen.
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  // Tracks which card's delete is in flight, so only THAT card shows a
  // spinner - adminCategoryControllerProvider only holds one in-flight
  // mutation at a time, not which category it belongs to.
  String? _busyCategoryId;

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${category.name}" will be removed. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    _busyCategoryId = category.id;
    await ref.read(adminCategoryControllerProvider.notifier).deleteCategory(category.id);
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
      // A successful delete looks identical to the initial list fetch (both
      // are "was loading, now has a value") - only show the toast when this
      // was actually a mutation, tracked by _busyCategoryId being set.
      if (next.hasValue && previous?.isLoading == true && _busyCategoryId != null) {
        _busyCategoryId = null;
        AppToast.success(context, 'Category deleted.');
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
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminCategoryControllerProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.gutter,
                AppSpacing.gutter,
                AppSpacing.gutter + 72, // clears the FAB
              ),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isBusy = categoriesState.isLoading && _busyCategoryId == category.id;
                return Card(
                  child: ListTile(
                    title: Text(category.name, style: textTheme.titleMedium),
                    subtitle: category.description != null && category.description!.isNotEmpty
                        ? Text(category.description!)
                        : null,
                    trailing: isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => context.push('/admin/categories/form', extra: category),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                onPressed: () => _delete(category),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
