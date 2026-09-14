import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// What FiltersSheet hands back when "Show results" is tapped - null
/// fields mean "no filter", same convention ProviderBrowseQuery uses.
typedef ProviderFilters = ({String? district, double? minRating, double? maxPrice});

/// A fixed, small set of Kigali-area districts (plus Musanze, since the
/// seed data includes a provider there) - not backed by a real "district"
/// field on the backend (ProviderProfile.location is free text), so this
/// is deliberately a short curated list rather than something fetched.
/// See ProviderBrowseQuery's doc comment for how the match itself works.
const _districts = ['Kicukiro', 'Gasabo', 'Nyarugenge', 'Musanze'];

const _maxPriceCeiling = 50000.0;

/// The Filters bottom sheet (mockup screen B4) - district chips, a max
/// price slider, and minimum-rating chips. Shown via [show], which
/// returns the chosen ProviderFilters (or null if dismissed without
/// tapping "Show results").
class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key, required this.initial});

  final ProviderFilters initial;

  static Future<ProviderFilters?> show(BuildContext context, ProviderFilters initial) {
    return showModalBottomSheet<ProviderFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltersSheet(initial: initial),
    );
  }

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late String? _district = widget.initial.district;
  late double _maxPrice = widget.initial.maxPrice ?? _maxPriceCeiling;
  late double? _minRating = widget.initial.minRating;

  void _reset() {
    setState(() {
      _district = null;
      _maxPrice = _maxPriceCeiling;
      _minRating = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          top: AppSpacing.md,
          bottom: AppSpacing.gutter + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: Text('Filters', style: textTheme.headlineSmall)),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('District', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final district in _districts)
                  ChoiceChip(
                    label: Text(district),
                    selected: _district == district,
                    onSelected: (selected) => setState(() => _district = selected ? district : null),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: [
                Expanded(child: Text('Max price', style: textTheme.titleMedium)),
                Text(
                  _maxPrice >= _maxPriceCeiling ? '${_maxPriceCeiling.toStringAsFixed(0)}+ RWF' : '${_maxPrice.toStringAsFixed(0)} RWF',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
            Slider(
              value: _maxPrice,
              min: 0,
              max: _maxPriceCeiling,
              divisions: 20,
              onChanged: (value) => setState(() => _maxPrice = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Minimum rating', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final (label, value) in [('Any', null), ('4.0+', 4.0), ('4.5+', 4.5)])
                  ChoiceChip(
                    label: Text(label),
                    selected: _minRating == value,
                    onSelected: (_) => setState(() => _minRating = value),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((
                district: _district,
                minRating: _minRating,
                maxPrice: _maxPrice >= _maxPriceCeiling ? null : _maxPrice,
              )),
              child: const Text('Show results'),
            ),
          ],
        ),
      ),
    );
  }
}
