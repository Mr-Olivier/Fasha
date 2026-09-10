import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../admin/presentation/admin_provider_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../providers/presentation/provider_profile_controller.dart';
import '../../providers/presentation/verification_badge.dart';
import '../../services/presentation/category_controller.dart';
import '../../services/presentation/category_tile.dart';

/// Splits into a customer view and a provider view, since the two roles
/// have almost nothing in common here. Customer discovery/booking (Feature
/// 5+) doesn't exist yet, so the customer view only shows what's actually
/// real right now: the live category list from GET /api/categories.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      // Logging out lives in the Profile tab now (see AppShell) - matching
      // Instagram/Facebook, account actions belong in a Profile tab, not
      // scattered as an icon on every other screen's app bar.
      appBar: AppBar(title: const Text('FASHA APP'), actions: const [_NotificationBell()]),
      body: switch (user) {
        null => const Center(child: Text('No user logged in.')),
        AuthUser(role: UserRole.provider) => const _ProviderHome(),
        AuthUser(role: UserRole.admin) => const _AdminHome(),
        _ => _CustomerHome(user: user),
      },
    );
  }
}

/// Visible in every role's Home app bar (unlike the rest of this screen,
/// which splits by role) since any role can receive a notification.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.read).length ?? 0;

    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        label: Text('$unreadCount'),
        isLabelVisible: unreadCount > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _CustomerHome extends ConsumerWidget {
  const _CustomerHome({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final firstName = user.name.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muraho, $firstName', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.gutter),
          _SearchProvidersBar(onTap: () => context.push('/providers')),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(child: Text('Categories', style: textTheme.titleLarge)),
              InkWell(
                onTap: () => context.push('/categories'),
                borderRadius: BorderRadius.circular(AppRadii.chip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                  child: Text(
                    'See all',
                    style: textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // A 4-column grid capped at 7 categories (+1 "more" tile) rather
          // than showing every category - matches the "Categories" section
          // of the project's own design reference (fasha-app-final-ui.html,
          // screen B1); the full, searchable list lives on AllCategoriesScreen
          // ("See all" above, or the "+N" tile below).
          categoriesState.when(
            loading: () => const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => const Text('Could not load categories.'),
            data: (categories) {
              const maxShown = 7;
              final showMoreTile = categories.length > maxShown;
              final shown = showMoreTile ? categories.take(maxShown).toList() : categories;

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.78,
                children: [
                  for (final category in shown)
                    CategoryTile(
                      category: category,
                      onTap: () => context.push(
                        '/providers?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
                      ),
                    ),
                  if (showMoreTile)
                    _MoreCategoriesTile(count: categories.length - maxShown, onTap: () => context.push('/categories')),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.gutter),
          _DashboardTile(
            icon: Icons.event_note_outlined,
            title: 'My bookings',
            subtitle: 'Track requests you\'ve sent to providers',
            onTap: () => context.push('/my-bookings'),
          ),
        ],
      ),
    );
  }
}

/// The 8th cell of the category grid when there are more categories than
/// fit - same tile shape as [CategoryTile] (so it doesn't stick out), but a
/// neutral badge and a "+N" count instead of an icon, leading to
/// AllCategoriesScreen for the rest.
class _MoreCategoriesTile extends StatelessWidget {
  const _MoreCategoriesTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.field),
              ),
              child: Center(
                child: Text(
                  '+$count',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('More', style: textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// A tap target styled like a search field, not an actual TextField - the
/// real search input lives on ProviderListScreen (see its own doc comment
/// for why search and category are independent filters there). This just
/// gets a customer there without first having to tap a category tile.
class _SearchProvidersBar extends StatelessWidget {
  const _SearchProvidersBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search providers by name or location',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderHome extends ConsumerWidget {
  const _ProviderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(providerProfileControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    if (profileState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = profileState.valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile == null) ...[
            Text('Set up your provider profile', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Add your business name, description and services so customers can find you once search launches.',
            ),
          ] else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.businessName, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      VerificationBadge(status: profile.verificationStatus),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.gutter),
          _DashboardTile(
            icon: Icons.storefront_outlined,
            title: 'Manage my profile',
            subtitle: profile == null ? 'Create your profile' : 'Edit your business details',
            onTap: () => context.push('/provider-profile'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DashboardTile(
            icon: Icons.build_outlined,
            title: 'My services',
            subtitle: 'Add and edit what you offer',
            onTap: () => context.push('/my-services'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DashboardTile(
            icon: Icons.inbox_outlined,
            title: 'Incoming requests',
            subtitle: 'Accept, reject, and manage bookings',
            onTap: () => context.push('/incoming-requests'),
          ),
        ],
      ),
    );
  }
}

class _AdminHome extends ConsumerWidget {
  const _AdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingState = ref.watch(pendingProvidersProvider);
    final textTheme = Theme.of(context).textTheme;
    final pendingCount = pendingState.valueOrNull?.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.gutter),
          _DashboardTile(
            icon: Icons.fact_check_outlined,
            title: 'Provider approvals',
            subtitle: pendingCount == null
                ? 'Review new provider applications'
                : '$pendingCount application${pendingCount == 1 ? '' : 's'} waiting for review',
            onTap: () => context.push('/admin/providers'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DashboardTile(
            icon: Icons.category_outlined,
            title: 'Manage categories',
            subtitle: 'Add, rename, or remove service categories',
            onTap: () => context.push('/admin/categories'),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
