import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent bottom tab bar wrapping Home and Profile - the same
/// pattern Instagram/Facebook use: tabs keep their own navigation state
/// (switching away and back doesn't reset scroll position or lose your
/// place), unlike plain push/pop navigation between two unrelated routes.
///
/// GoRouter provides this via StatefulShellRoute.indexedStack (wired in
/// app_router.dart) - [navigationShell] is what that route hands us; each
/// "branch" is a fully independent Navigator stack, and `navigationShell`
/// itself is the widget that actually displays whichever branch is active.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the tab you're ALREADY on resets it back to that
          // branch's own starting route, instead of doing nothing - the
          // same "tap Home again to scroll to top / reset" behaviour
          // those apps have.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
