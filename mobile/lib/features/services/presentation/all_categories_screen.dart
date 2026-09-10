import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'category_controller.dart';
import 'category_icon_badge.dart';

/// The full category list, reached via "See all" on Home's category grid
/// (which only ever shows the first 7 plus a "+N more" tile) - matches
/// screen B2 of the project's own design reference
/// (`fasha-app-final-ui.html`): a back header, a search field, and every
/// category as a full-width row instead of a grid cell.
///
/// Filtering is done client-side against the same `categoriesProvider`
/// Home uses, rather than a dedicated search endpoint - with only a few
/// dozen categories total, fetching them once and filtering in memory is
/// simpler than adding backend search for no real benefit.
class AllCategoriesScreen extends ConsumerStatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  ConsumerState<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends ConsumerState<AllCategoriesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load categories.')),
        data: (categories) {
          final filtered = _search.isEmpty
              ? categories
              : categories.where((category) => category.name.toLowerCase().contains(_search.toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, AppSpacing.sm),
                child: TextField(
                  onChanged: (value) => setState(() => _search = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search ${categories.length} categories',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.gutter),
                          child: Text(
                            'No categories match "$_search".',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          0,
                          AppSpacing.gutter,
                          AppSpacing.gutter,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final category = filtered[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: SizedBox(
                                width: 48,
                                height: 48,
                                child: CategoryIconBadge(category: category, iconSize: 22),
                              ),
                              title: Text(category.name, style: textTheme.titleMedium),
                              subtitle: category.description != null && category.description!.isNotEmpty
                                  ? Text(category.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                '/providers?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
