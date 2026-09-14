import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/provider_card.dart';
import '../../services/presentation/category_controller.dart';
import 'filters_sheet.dart';
import 'provider_browse_controller.dart';

/// Customer-facing: approved providers, optionally narrowed by category,
/// district/rating/price (the Filters sheet), and/or a free-text search
/// term. [categoryId]/[categoryName] seed the initial category filter when
/// reached by tapping a category tile on Home; both are null when reached
/// as "browse/search all providers" instead, in which case the category
/// filter starts on "All".
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
  ProviderFilters _filters = (district: null, minRating: null, maxPrice: null);

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

  Future<void> _openFilters() async {
    final result = await FiltersSheet.show(context, _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  int get _activeFilterCount =>
      (_filters.district != null ? 1 : 0) + (_filters.minRating != null ? 1 : 0) + (_filters.maxPrice != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final query = (
      categoryId: _selectedCategoryId,
      search: _search.isEmpty ? null : _search,
      district: _filters.district,
      minRating: _filters.minRating,
      maxPrice: _filters.maxPrice,
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
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ActionChip(
                    avatar: Icon(Icons.tune, size: 18, color: _activeFilterCount > 0 ? colorScheme.primary : null),
                    label: Text(_activeFilterCount > 0 ? 'Filters · $_activeFilterCount' : 'Filters'),
                    onPressed: _openFilters,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) => setState(() => _selectedCategoryId = null),
                  ),
                ),
                categoriesState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (categories) => Row(
                    children: [
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
              ],
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
                            ? 'No approved providers match these filters yet.'
                            : 'No providers match "$_search".',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                      child: Text(
                        '${providers.length} provider${providers.length == 1 ? '' : 's'}',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: ListView.separated(
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
                          return ProviderCard(
                            provider: provider,
                            onTap: () => context.push('/providers/${provider.id}'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
