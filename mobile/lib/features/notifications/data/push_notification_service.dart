import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import '../../../core/config/app_config.dart';
import 'device_token_api.dart';

/// Registers/unregisters this install for push notifications - called
/// directly from AuthController (`_registerPushTokenIfSignedIn` after
/// register/login/Google sign-in, and the start of `logout()`), the same
/// place it already calls GoogleAuthService.signOut() for equivalent
/// session-lifecycle cleanup.
///
/// Every method here is deliberately fail-silent (logs, never throws):
/// push notifications are a nice-to-have, and a Firebase hiccup (or, during
/// local dev before a real Firebase project exists at all, an outright
/// missing config - see AppConfig's Firebase fields) must never be allowed
/// to break login/logout, which is what would happen if this propagated an
/// exception into AuthController's own AsyncValue.guard.
class PushNotificationService {
  const PushNotificationService(this._deviceTokenApi);

  final DeviceTokenApi _deviceTokenApi;

  static bool get _isConfigured =>
      AppConfig.firebaseApiKey.isNotEmpty &&
      AppConfig.firebaseAppId.isNotEmpty &&
      AppConfig.firebaseMessagingSenderId.isNotEmpty &&
      AppConfig.firebaseProjectId.isNotEmpty;

  static FirebaseOptions get _options => const FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
      );

  /// Call once, right after a successful login/register/Google sign-in.
  /// Initializes Firebase (if this is the first time), asks for
  /// notification permission, and registers this device's FCM token with
  /// our backend - all best-effort.
  Future<void> registerThisDevice() async {
    if (!_isConfigured) {
      debugPrint('PushNotificationService: Firebase not configured (see AppConfig) - skipping push registration.');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _options);
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('PushNotificationService: notification permission denied by the user.');
        return;
      }

      final token = await messaging.getToken();
      if (token != null) {
        await _deviceTokenApi.register(token: token, platform: kIsWeb ? 'WEB' : 'ANDROID');
      }

      // FCM occasionally rotates a device's token (e.g. after the app is
      // restored on a new device, or its local storage is cleared) - each
      // new one needs registering too, for as long as this listener stays
      // alive (i.e. for the rest of this logged-in session).
      messaging.onTokenRefresh.listen((refreshedToken) {
        _deviceTokenApi.register(token: refreshedToken, platform: kIsWeb ? 'WEB' : 'ANDROID').catchError((Object e) {
          debugPrint('PushNotificationService: failed to register a refreshed token: $e');
        });
      });
    } catch (e) {
      debugPrint('PushNotificationService: failed to register this device for push notifications: $e');
    }
  }

  /// Call on logout - best-effort removal so a signed-out device stops
  /// being pushed to under its old user's notifications.
  Future<void> unregisterThisDevice() async {
    if (!_isConfigured) return;

    try {
      if (Firebase.apps.isEmpty) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _deviceTokenApi.unregister(token);
      }
    } catch (e) {
      debugPrint('PushNotificationService: failed to unregister this device: $e');
    }
  }
}
