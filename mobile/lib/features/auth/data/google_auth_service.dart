import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';

/// Thin wrapper around the `google_sign_in` package - isolates the rest of
/// the app from that package's API, and is the one place that reads
/// [AppConfig.googleOAuthClientId].
///
/// Web and Android need the same Google Cloud "Web application" client ID
/// passed through two different constructor params (that's how the
/// `google_sign_in` package expects it) - see AppConfig's doc comment for
/// why one value covers both.
class GoogleAuthService {
  GoogleAuthService()
      : _googleSignIn = GoogleSignIn(
          scopes: const ['email'],
          clientId: kIsWeb && AppConfig.googleOAuthClientId.isNotEmpty ? AppConfig.googleOAuthClientId : null,
          serverClientId: !kIsWeb && AppConfig.googleOAuthClientId.isNotEmpty ? AppConfig.googleOAuthClientId : null,
        );

  final GoogleSignIn _googleSignIn;

  /// Runs Google's sign-in flow and returns the ID token to send to our
  /// backend for verification - or null if the user backed out without
  /// choosing an account (not an error, just "never mind").
  ///
  /// Web and native deliberately call different methods here, both
  /// documented by the `google_sign_in` package as the ones that actually
  /// populate an ID token:
  ///  - Native (Android): `signIn()` shows the interactive account picker.
  ///  - Web: Google's newer Identity Services SDK split "authentication"
  ///    (who you are - what we need) from "authorization" (app
  ///    permissions), and `signIn()` on web now only returns an OAuth
  ///    access token, never an idToken. `signInSilently()` is what
  ///    actually triggers Google's "One Tap" prompt and returns an
  ///    idToken there - see the google_sign_in_web package README's
  ///    "Migrating to v0.11 and v0.12" section.
  Future<String?> signInAndGetIdToken() async {
    // Without a real client ID, Google's SDK just quietly returns no
    // account instead of erroring - which would otherwise make this
    // button look broken (nothing happens at all) rather than clearly
    // "not set up yet" during local dev before Google Cloud credentials
    // exist. See AppConfig.googleOAuthClientId's doc comment.
    if (AppConfig.googleOAuthClientId.isEmpty) {
      throw const ApiException("Google sign-in isn't set up yet on this build.");
    }

    final account = kIsWeb ? await _googleSignIn.signInSilently() : await _googleSignIn.signIn();
    if (account == null) return null;

    final authentication = await account.authentication;
    return authentication.idToken;
  }

  /// Clears Google's own cached account choice, so the next sign-in shows
  /// the account picker again instead of silently reusing the last choice.
  /// Called from AuthController.logout() alongside our own session clear.
  Future<void> signOut() => _googleSignIn.signOut();
}
