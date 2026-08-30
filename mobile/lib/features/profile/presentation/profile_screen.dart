import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

/// The account tab - who's logged in, and the one place "Log out" lives
/// now (it used to be an icon in HomeScreen's app bar; matching how
/// Instagram/Facebook put account actions in a Profile tab, not scattered
/// across every screen's app bar).
///
/// Not to be confused with ProviderProfileScreen (features/providers) -
/// that's the provider's public BUSINESS profile (name, description,
/// services); this is the logged-in user's own ACCOUNT screen, which every
/// role has.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('No user logged in.'))
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(user.name, style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(user.email, style: textTheme.bodyMedium),
                        Text(
                          '${user.role.name[0].toUpperCase()}${user.role.name.substring(1)}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Log out'),
                      onTap: () => ref.read(authControllerProvider.notifier).logout(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
