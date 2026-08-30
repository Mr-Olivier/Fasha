import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
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
      appBar: AppBar(
        title: const Text('KaziLink Rwanda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: switch (user) {
        null => const Center(child: Text('No user logged in.')),
        AuthUser(role: UserRole.provider) => const _ProviderHome(),
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
          Text('Categories', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          categoriesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Text('Could not load categories.'),
            data: (categories) => Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final category in categories)
                  CategoryTile(
                    category: category,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Provider search is coming in a future update.')),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Provider search and booking launch in a later update. For now, providers can set up '
                'their profile and services.',
                style: textTheme.bodyMedium,
              ),
            ),
          ),
        ],
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
