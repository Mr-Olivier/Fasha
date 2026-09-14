import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/star_rating.dart';
import '../../services/presentation/category_controller.dart';
import 'provider_browse_controller.dart';

/// Customer-facing: approved providers, optionally narrowed by category
/// and/or a free-text search term. [categoryId]/[categoryName] seed the
/// initial category filter when reached by tapping a category tile on
/// Home; both are null when reached as "browse/search all providers"
/// instead, in which case the category filter starts on "All".
///
/// A search term and a category filter are independent state here (not
/// combined into one text field) since they answer different questions -
/// "what kind of service" vs. "which specific provider/place" - and the
/// backend already treats them as two filters that AND together (see
/// ProviderProfileService.browseProviders on the backend).
class ProviderListScreen extends ConsumerStatefulWidget {
  const ProviderListScreen({super.key, this.categoryId, this.categoryName});

  final String? categoryId;
  final String? categoryName;

  @override
  ConsumerState<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends ConsumerState<ProviderListScreen> {
  late final _searchController = TextEditingController();
  late String? _selectedCategoryId = widget.categoryId;
  String _search = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Waits for a short pause in typing before re-querying, rather than
  /// firing a request per keystroke - the filtering itself is cheap
  /// (see ProviderProfileService.browseProviders), but there's no reason
  /// to fire five requests for someone typing a five-letter word.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = (
      categoryId: _selectedCategoryId,
      search: _search.isEmpty ? null : _search,
      district: null,
      minRating: null,
      maxPrice: null,
    );
    final providersState = ref.watch(providerBrowseProvider(query));
    final categoriesState = ref.watch(categoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName ?? 'Find a provider')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
            ),
          ),
          categoriesState.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
            data: (categories) => SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        onSelected: (_) => setState(() => _selectedCategoryId = category.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: providersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const Center(child: Text('Could not load providers.')),
              data: (providers) {
                if (providers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      child: Text(
                        _search.isEmpty
                            ? 'No approved providers offer this yet. Check back soon.'
                            : 'No providers match "$_search".',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.gutter,
                  ),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(provider.location ?? 'Location not specified'),
                            const SizedBox(height: 2),
                            if (provider.averageRating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StarRating(rating: provider.averageRating!, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${provider.averageRating!.toStringAsFixed(1)} (${provider.reviewCount})',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              )
                            else
                              Text('No reviews yet', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/providers/${provider.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
