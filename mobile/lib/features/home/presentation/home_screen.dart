import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/provider_card.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../admin/domain/pending_provider.dart';
import '../../admin/presentation/admin_dashboard_charts.dart';
import '../../admin/presentation/admin_provider_controller.dart';
import '../../admin/presentation/admin_stats_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../bookings/domain/booking_status.dart';
import '../../bookings/presentation/booking_controller.dart';
import '../../bookings/presentation/provider_dashboard_screen.dart';
import '../../providers/presentation/provider_browse_controller.dart';
import '../../services/presentation/category_controller.dart';
import '../../services/presentation/category_tile.dart';

/// Splits by role - a provider's "Home" branch shows ProviderDashboardScreen
/// (their "Jobs" tab, labelled that way instead of "Home" by AppShell),
/// keeping the same shared Scaffold/AppBar every role's Home branch uses
/// rather than each screen nesting its own. Customer discovery/booking only
/// shows what's actually real right now: the live category list from
/// GET /api/categories.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      // Logging out lives in the Profile tab now (see AppShell) - matching
      // Instagram/Facebook, account actions belong in a Profile tab, not
      // scattered as an icon on every other screen's app bar.
      appBar: BrandedAppBar(
        title: switch (user?.role) {
          UserRole.provider => 'Fasha Pro',
          _ => 'Fasha',
        },
        subtitle: switch (user?.role) {
          UserRole.provider => 'Provider dashboard',
          UserRole.admin => 'Admin overview',
          _ => 'Kigali, Rwanda',
        },
        actions: const [NotificationBell()],
      ),
      body: switch (user) {
        null => const Center(child: Text('No user logged in.')),
        AuthUser(role: UserRole.provider) => const ProviderDashboardScreen(),
        AuthUser(role: UserRole.admin) => const _AdminHome(),
        _ => _CustomerHome(user: user),
      },
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
          _SearchProvidersBar(onTap: () => context.go('/providers')),
          const SizedBox(height: AppSpacing.gutter),
          const _ActiveBookingBanner(),
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
                      onTap: () => context.go(
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
            onTap: () => context.go('/bookings'),
          ),
          const SizedBox(height: AppSpacing.gutter),
          const _TopRatedSection(),
        ],
      ),
    );
  }
}

/// A summary card for the customer's first ACCEPTED/IN_PROGRESS booking
/// (if any), tapping through to its Booking Tracker - lets a customer with
/// something already under way see it without going to the Bookings tab
/// first. Renders nothing at all when there's no active booking, rather
/// than an empty-state placeholder - Home already has plenty else to show.
class _ActiveBookingBanner extends ConsumerWidget {
  const _ActiveBookingBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsControllerProvider).valueOrNull ?? const [];
    final active = bookings
        .where((b) => b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress)
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final booking = active.first;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // A bold, colour-blocked callout (not an inverted-surface card) - the
    // same brand-teal treatment the design reference gives "upcoming
    // service"/"active booking" banners, so it stays a deliberate highlight
    // in both themes instead of flipping to a stark near-white box against
    // an otherwise dark page.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Material(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () => context.push('/booking-tracker', extra: booking),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.status == BookingStatus.inProgress ? 'ACTIVE BOOKING' : 'UPCOMING BOOKING',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.75),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.providerBusinessName} is ${booking.status == BookingStatus.inProgress ? 'working now' : 'on the way'}',
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
                      ),
                      Text(
                        booking.serviceName,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The top 5 approved providers by rating, reusing the same browse
/// endpoint the Explore tab uses (no separate "top rated" endpoint exists
/// on the backend - sorting the already-returned averageRating client-side
/// is enough at this dataset size, same reasoning ProviderProfileService's
/// own in-memory filtering already uses).
class _TopRatedSection extends ConsumerWidget {
  const _TopRatedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersState = ref.watch(
      providerBrowseProvider((categoryId: null, search: null, district: null, minRating: null, maxPrice: null)),
    );
    final textTheme = Theme.of(context).textTheme;

    return providersState.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (providers) {
        final rated = providers.where((p) => p.averageRating != null).toList()
          ..sort((a, b) => b.averageRating!.compareTo(a.averageRating!));
        if (rated.isEmpty) return const SizedBox.shrink();
        final top = rated.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top rated near you', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final provider in top) ...[
              ProviderCard(provider: provider, onTap: () => context.push('/providers/${provider.id}')),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
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

/// Matches the "Admin Overview" screen from the project's design reference
/// (E1): a hero card + icon-based stat grid (the same visual language
/// ProviderDashboardScreen's own hero/_StatTile pair uses, so all three
/// role dashboards read as one deliberate design system rather than the
/// admin one looking like an afterthought), then a "Needs your action"
/// queue of pending provider applications. The design also shows a
/// reported-review item in that queue - left out here since nothing in the
/// app yet lets anyone report a review (a separate feature, not an admin
/// screen restyle - see PROJECT_STATUS.md).
class _AdminHome extends ConsumerWidget {
  const _AdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(adminStatsProvider);
    final pendingState = ref.watch(pendingProvidersProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => Future.wait([
        ref.refresh(adminStatsProvider.future),
        ref.refresh(pendingProvidersProvider.future),
      ]),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdminHeroCard(pendingApprovals: statsState.valueOrNull?.pendingApprovals),
            const SizedBox(height: AppSpacing.gutter),
            Text('Platform pulse', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            statsState.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => const Text('Could not load stats.'),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 2.1,
                children: [
                  _StatTile(
                    value: '${stats.pendingApprovals}',
                    label: 'Pending approvals',
                    icon: Icons.inbox_outlined,
                    color: colorScheme.secondary,
                  ),
                  _StatTile(
                    value: '${stats.activeProviders}',
                    label: 'Active providers',
                    icon: Icons.storefront_outlined,
                    color: colorScheme.primary,
                  ),
                  _StatTile(
                    value: '${stats.totalCustomers}',
                    label: 'Customers',
                    icon: Icons.group_outlined,
                    color: colorScheme.tertiary,
                  ),
                  _StatTile(
                    value: '${stats.bookingsLast30Days}',
                    label: 'Bookings (30d)',
                    icon: Icons.calendar_month_outlined,
                    color: colorScheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            const AdminDashboardCharts(),
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: [
                Expanded(child: Text('Needs your action', style: textTheme.titleLarge)),
                InkWell(
                  onTap: () => context.go('/admin/providers'),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                    child: Text(
                      'All',
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            pendingState.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (error, _) => const Text('Could not load pending applications.'),
              data: (pending) {
                if (pending.isEmpty) {
                  return Text(
                    'Nothing needs your review right now.',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  );
                }
                return Column(
                  children: [
                    for (final provider in pending.take(3)) ...[
                      _NeedsActionTile(provider: provider, onTap: () => context.go('/admin/providers')),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.gutter),
            _DashboardTile(
              icon: Icons.history,
              title: 'Activity log',
              subtitle: 'See recent admin actions - approvals, suspensions, deletes',
              onTap: () => context.push('/admin/audit-log'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The admin Overview's colour-blocked header, same treatment
/// ProviderDashboardScreen's own hero card gives a provider's business name
/// - here it's the platform itself, with a badge surfacing whether
/// anything actually needs the admin's attention right now instead of
/// making them scan the stat grid below to find out.
class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({required this.pendingApprovals});

  final int? pendingApprovals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasPending = (pendingApprovals ?? 0) > 0;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fasha platform',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text('Admin dashboard', style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary)),
                ],
              ),
            ),
            if (pendingApprovals != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  child: Text(
                    hasPending ? '$pendingApprovals TO REVIEW' : 'ALL CLEAR',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One cell of the admin Overview's stat grid - identical shape to
/// ProviderDashboardScreen's own private _StatTile (an icon in a tinted
/// circle + value/label), kept as its own copy here rather than extracted
/// into a shared widget since each screen's tile count/colours are
/// different enough that a shared version would need almost as many
/// parameters as just having two small private classes.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.icon, required this.color});

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: textTheme.titleLarge),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the admin Overview's "Needs your action" queue - a pending
/// provider application, styled like the design's list cards (avatar
/// initial, name, "location · applied X" subtitle, a status chip).
class _NeedsActionTile extends StatelessWidget {
  const _NeedsActionTile({required this.provider, required this.onTap});

  final PendingProvider provider;
  final VoidCallback onTap;

  static String _relative(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurfaceVariant,
                child: Text(
                  provider.businessName.isNotEmpty ? provider.businessName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.businessName, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      [provider.location, _relative(provider.appliedAt)]
                          .where((part) => part != null && part.isNotEmpty)
                          .join(' · '),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: StatusColors.pending(context).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  child: Text(
                    'PENDING',
                    style: textTheme.labelSmall?.copyWith(
                      color: StatusColors.pending(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
