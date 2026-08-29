import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    // ProviderScope stores the state of every Riverpod provider in the app.
    // It must wrap the app exactly once, at the very root - every feature's
    // providers (auth, bookings, ...) will read/write through this scope.
    const ProviderScope(child: KaziLinkApp()),
  );
}

/// ConsumerWidget (not StatelessWidget) because we need `ref` to read
/// appRouterProvider - GoRouter itself is built from Riverpod state (see
/// app_router.dart), so the widget that hands it to MaterialApp.router
/// has to be Riverpod-aware too.
class KaziLinkApp extends ConsumerWidget {
  const KaziLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'KaziLink Rwanda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // "system" follows the phone's own setting, per README section 15.
      // Letting the user override this (and persisting the choice) is a
      // later feature - see the roadmap's "Theme, polish" day.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
