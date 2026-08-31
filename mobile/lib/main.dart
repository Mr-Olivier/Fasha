import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';

void main() {
  runApp(
    // ProviderScope stores the state of every Riverpod provider in the app.
    // It must wrap the app exactly once, at the very root - every feature's
    // providers (auth, bookings, ...) will read/write through this scope.
    const ProviderScope(child: FashaApp()),
  );
}

/// ConsumerWidget (not StatelessWidget) because we need `ref` to read
/// appRouterProvider - GoRouter itself is built from Riverpod state (see
/// app_router.dart), so the widget that hands it to MaterialApp.router
/// has to be Riverpod-aware too.
class FashaApp extends ConsumerWidget {
  const FashaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'FASHA APP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Defaults to following the phone's own setting, but the user can
      // override it from Profile > Appearance - see ThemeModeController.
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
