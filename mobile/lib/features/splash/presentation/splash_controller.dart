import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Facebook/Instagram-style splash: held on screen for a fixed minimum
/// time, regardless of how fast AuthController's session restore actually
/// finishes (reading local secure storage is usually near-instant - well
/// under a second). Without this, the splash would flash by too quickly
/// to register as a screen at all, let alone build any brand recognition.
///
/// app_router.dart's redirect only leaves "/splash" once BOTH this AND
/// AuthController have resolved - whichever takes longer wins, so a slow
/// device or a slow disk read never gets CUT SHORT by this timer either.
final splashMinimumDurationProvider = FutureProvider<void>((ref) {
  return Future<void>.delayed(const Duration(seconds: 5));
});
