import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';

/// Placeholder landing screen, just to prove the auth loop works end to
/// end: register/login lands here, this shows who's logged in, and
/// logging out sends the router back to /login. Real home-screen content
/// (categories, provider search, ...) is a later feature.
///
/// The one piece of real functionality so far: a PROVIDER sees a button
/// into their profile (README.md Day 4's "provider dashboard"). A CUSTOMER
/// doesn't, since customer-facing discovery doesn't exist yet either.
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
      body: Center(
        child: user == null
            ? const Text('No user logged in.')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(user.email),
                  Text('Role: ${user.role.name}'),
                  if (user.role == UserRole.provider) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.push('/provider-profile'),
                      child: const Text('Manage my profile'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
