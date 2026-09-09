/// Build-time configuration that differs between local dev and production
/// without needing any code changes - only the `--dart-define` value passed
/// to `flutter run`/`flutter build` differs. See NEXT_SESSION.md for the
/// full Google Cloud Console setup checklist.
class AppConfig {
  AppConfig._();

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
}
