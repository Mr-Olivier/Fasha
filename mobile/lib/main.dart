import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(
    // ProviderScope stores the state of every Riverpod provider in the app.
    // It must wrap the app exactly once, at the very root - every feature's
    // providers (auth, bookings, ...) will read/write through this scope.
    const ProviderScope(child: KaziLinkApp()),
  );
}

class KaziLinkApp extends StatelessWidget {
  const KaziLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaziLink Rwanda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // "system" follows the phone's own setting, per README section 15.
      // Letting the user override this (and persisting the choice) is a
      // later feature - see the roadmap's "Theme, polish" day.
      themeMode: ThemeMode.system,
      home: const _SetupCheckScreen(),
    );
  }
}

/// Temporary placeholder home screen.
///
/// This exists only to prove the app boots end-to-end with our theme wired
/// in. It will be replaced by GoRouter + the real splash/login screen in the
/// Authentication feature - see README.md section 21, Feature 2.
class _SetupCheckScreen extends StatelessWidget {
  const _SetupCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KaziLink Rwanda')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Project setup complete.\nAuthentication screens come next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
