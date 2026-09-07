import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingPrefsKey = 'onboarding_completed';

/// Whether the 3-slide carousel has ever been finished (or skipped) on
/// this device - a FutureProvider since SharedPreferences reads are async,
/// same reasoning as ThemeModeController.build() needing its own restore
/// step rather than reading synchronously.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingPrefsKey) ?? false;
});

/// Called once, from either "Skip" or finishing the last slide - both mean
/// the same thing: never show this again. Invalidating the provider (
/// rather than just navigating away) is what lets app_router.dart's
/// redirect logic re-check and stop sending this device back to
/// /onboarding on a future cold start.
Future<void> markOnboardingCompleted(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingPrefsKey, true);
  ref.invalidate(onboardingCompletedProvider);
}
