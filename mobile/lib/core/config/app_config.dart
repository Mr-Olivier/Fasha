/// Build-time configuration that differs between local dev and production
/// without needing any code changes - only the `--dart-define` value passed
/// to `flutter run`/`flutter build` differs. See NEXT_SESSION.md for the
/// full Google Cloud Console setup checklist.
class AppConfig {
  AppConfig._();

  /// Overrides ApiClient's default `http://localhost:8081/api` - only
  /// needed to reach the backend from a device where "localhost" doesn't
  /// mean this machine (a phone on the same Wi-Fi, testing real-time chat
  /// against a browser tab running here), e.g.
  /// `--dart-define=API_BASE_URL=http://192.168.1.x:8081/api`. Empty until
  /// set, same "inert until configured" story as every other value below -
  /// the normal `flutter run` dev loop needs nothing here.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// The Google OAuth "Web application" client ID from Google Cloud
  /// Console. Used as-is on Flutter Web (as `clientId`) and on Android (as
  /// `serverClientId`, so the ID token Android hands back is audienced to
  /// this same client) - see GoogleAuthService. One value, every platform,
  /// so nothing about the sign-in code itself needs to change between
  /// environments; only this value does.
  ///
  /// Empty until set, which is what lets local dev boot and use the rest
  /// of the app fine before Google Sign-In is configured - only tapping
  /// "Continue with Google" itself fails, with a clear message.
  static const googleOAuthClientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');

  // --- Firebase (push notifications - see PushNotificationService) ---
  // Passed through --dart-define, deliberately NOT via the usual
  // `flutterfire configure`-generated google-services.json/
  // firebase_options.dart: those make the Android BUILD ITSELF fail
  // without a real Firebase project already set up, which would break
  // `flutter build`/`flutter run` for anyone before push notifications
  // are configured - the same "never break the build over an optional
  // integration" reasoning as every other optional config in this class.
  // Empty until set, same "inert until configured" story as
  // googleOAuthClientId above - see PushNotificationService.isConfigured.
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
}
