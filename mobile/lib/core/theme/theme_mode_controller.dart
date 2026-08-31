import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets the user override the phone's own light/dark setting from the
/// Profile screen ("Appearance: Light / Dark / System"), and remembers
/// that choice between app launches.
///
/// Starts as [ThemeMode.system] (the same default main.dart used to hard-code)
/// so the very first frame never flashes the wrong theme, then swaps to
/// whatever was saved last time as soon as that read finishes - shared
/// preferences is a plain key-value store, not something worth blocking
/// app startup on (unlike the JWT session in AuthSessionStorage, a theme
/// choice is low-stakes and fine to arrive a frame late).
class ThemeModeController extends Notifier<ThemeMode> {
  static const _prefsKey = 'appearance_mode';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == stored) {
        state = mode;
        return;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

final themeModeControllerProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
