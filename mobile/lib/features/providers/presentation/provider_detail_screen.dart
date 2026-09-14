import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/review_card.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reviews/presentation/review_controller.dart';
import '../../services/domain/service_listing.dart';
import 'provider_browse_controller.dart';

/// Customer-facing public profile - business info, a selectable services
/// list feeding a bottom-pinned "Request service" bar, and a preview of
/// reviews with a link to the full list (B6). Tapping the heart favorites/
/// unfavorites the provider (customer role only - a provider viewing a
/// peer, or an admin, never see it: see _canFavorite below).
class ProviderDetailScreen extends ConsumerStatefulWidget {
  const ProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  @override
  ConsumerState<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends ConsumerState<ProviderDetailScreen> {
  ServiceListing? _selected;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(providerDetailProvider(widget.providerId));
    final reviewsState = ref.watch(providerReviewsProvider(widget.providerId));
    final role = ref.watch(authControllerProvider).valueOrNull?.role;
    final canFavorite = role == UserRole.customer;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Provider')),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load this provider.')),
        data: (detail) {
          final profile = detail.profile;
          _selected ??= detail.services.where((s) => s.visible).cast<ServiceListing?>().firstWhere(
                (_) => true,
                orElse: () => null,
              );

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.businessName, style: textTheme.titleLarge),
                              if (profile.location != null) ...[
                                const SizedBox(height: 2),
                                Text(profile.location!, style: textTheme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                        if (canFavorite) _FavoriteButton(providerId: profile.id, isFavorited: profile.isFavorited),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: profile.averageRating?.toStringAsFixed(1) ?? '—',
                            label: '${profile.reviewCount} review${profile.reviewCount == 1 ? '' : 's'}',
                          ),
                        ),
                        Expanded(
                          child: _StatTile(value: '${detail.services.length}', label: 'services'),
                        ),
                        if (profile.yearsExperience != null)
                          Expanded(
                            child: _StatTile(value: '${profile.yearsExperience}', label: 'yrs experience'),
                          ),
                      ],
                    ),
                    if (profile.description != null && profile.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.gutter),
                      Text(profile.description!, style: textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.gutter),
                    Text('Services', style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    if (detail.services.isEmpty)
                      Text(
                        'This provider hasn\'t listed any services yet.',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      )
                    else
                      for (final service in detail.services.where((s) => s.visible)) ...[
                        _SelectableServiceTile(
                          service: service,
                          selected: _selected?.id == service.id,
                          onTap: () => setState(() => _selected = service),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    const SizedBox(height: AppSpacing.gutter),
                    Row(
                      children: [
                        Expanded(child: Text('Reviews', style: textTheme.titleLarge)),
                        TextButton(
                          onPressed: () => context.push('/providers/${widget.providerId}/reviews'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    reviewsState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(
                        'Could not load reviews.',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      data: (reviews) {
                        if (reviews.isEmpty) {
                          return Text(
                            'No reviews yet.',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final review in reviews.take(3)) ...[
                              ReviewCard(review: review),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_selected != null)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(top: BorderSide(color: colorScheme.outline)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECTED',
                                style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                              Text(
                                'RWF ${_selected!.price.toStringAsFixed(0)}',
                                style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                        // The theme's default FilledButton is full-width
                        // (minimumSize: Size.fromHeight(52), i.e. infinite
                        // width) - fine inside a stretched Column, but
                        // breaks layout as a bare (non-Expanded) child of a
                        // Row like this one. See request_card.dart's
                        // compactButtonStyle for the same fix elsewhere.
                        FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                          onPressed: () => context.push('/request-booking', extra: _selected),
                          child: const Text('Request service'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: textTheme.titleLarge),
        Text(label, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _SelectableServiceTile extends StatelessWidget {
  const _SelectableServiceTile({required this.service, required this.selected, required this.onTap});

  final ServiceListing service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer.withValues(alpha: 0.5) : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: textTheme.titleMedium),
                    Text(
                      service.description?.isNotEmpty == true ? service.description! : service.duration.label,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Text('RWF ${service.price.toStringAsFixed(0)}', style: textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.providerId, required this.isFavorited});

  final String providerId;
  final bool isFavorited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggling = ref.watch(favoriteToggleControllerProvider).isLoading;
    return IconButton(
      onPressed: toggling
          ? null
          : () => ref
              .read(favoriteToggleControllerProvider.notifier)
              .toggle(providerId, currentlyFavorited: isFavorited),
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color: isFavorited ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}
