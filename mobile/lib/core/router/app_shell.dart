import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/user_role.dart';
import '../../features/auth/presentation/auth_controller.dart';

/// The persistent bottom tab bar wrapping every top-level screen - the same
/// pattern Instagram/Facebook use: tabs keep their own navigation state
/// (switching away and back doesn't reset scroll position or lose your
/// place), unlike plain push/pop navigation between two unrelated routes.
///
/// GoRouter provides this via StatefulShellRoute.indexedStack (wired in
/// app_router.dart) - [navigationShell] is what that route hands us; each
/// "branch" is a fully independent Navigator stack, and `navigationShell`
/// itself is the widget that actually displays whichever branch is active.
///
/// The BRANCHES themselves (app_router.dart) are the same fixed five for
/// every role - Home, Providers, Customers, Categories, Profile - but which
/// ones actually show up as tabs depends on role: a customer/provider only
/// ever sees Home/Profile (the other three have nothing for them to do),
/// while an admin sees all five, since "easy navigation between Overview,
/// Providers, Customers, and Categories" is exactly the gap this class
/// closes. Reading the role here (rather than baking separate shells per
/// role into the router) keeps ONE shell/one set of branches, so switching
/// role never means switching navigation architecture underneath the user.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Each tuple is (branch index, icon, selected icon, label) - the branch
  // index is what StatefulNavigationShell.goBranch expects, NOT the
  // position within whichever destinations list a given role actually
  // sees (see _indexesFor/_displayedIndexFor below for that mapping).
  static const _home = (0, Icons.home_outlined, Icons.home, 'Home');
  static const _providers = (1, Icons.storefront_outlined, Icons.storefront, 'Providers');
  static const _customers = (2, Icons.group_outlined, Icons.group, 'Customers');
  static const _categories = (3, Icons.category_outlined, Icons.category, 'Categories');
  static const _profile = (4, Icons.person_outline, Icons.person, 'Profile');

  List<(int, IconData, IconData, String)> _destinationsFor(UserRole? role) => switch (role) {
        UserRole.admin => const [_home, _providers, _customers, _categories, _profile],
        _ => const [_home, _profile],
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).valueOrNull?.role;
    final destinations = _destinationsFor(role);

    // The branch currently on screen might not even be one of THIS role's
    // destinations (e.g. mid-role-switch, or a stale deep link) - fall back
    // to index 0 (Home) in the NavigationBar's own selection rather than
    // crashing on indexWhere returning -1.
    final selectedDisplayIndex = destinations.indexWhere((d) => d.$1 == navigationShell.currentIndex).clamp(
          0,
          destinations.length - 1,
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedDisplayIndex,
        onDestinationSelected: (displayIndex) {
          final branchIndex = destinations[displayIndex].$1;
          navigationShell.goBranch(
            branchIndex,
            // Tapping the tab you're ALREADY on resets it back to that
            // branch's own starting route, instead of doing nothing - the
            // same "tap Home again to scroll to top / reset" behaviour
            // those apps have.
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.$2), selectedIcon: Icon(d.$3), label: d.$4),
        ],
      ),
    );
  }
}
