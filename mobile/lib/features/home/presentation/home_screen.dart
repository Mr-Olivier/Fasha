import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
            : Padding(
                // The design system's buttons fill all available width
                // (see AppTheme's minimumSize) - without this padding
                // they'd stretch all the way to the screen edges, unlike
                // every other screen which already wraps its content this
                // way.
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome, ${user.name}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(user.email, textAlign: TextAlign.center),
                    Text('Role: ${user.role.name}', textAlign: TextAlign.center),
                    if (user.role == UserRole.provider) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.push('/provider-profile'),
                        child: const Text('Manage my profile'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/my-services'),
                        child: const Text('My services'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
