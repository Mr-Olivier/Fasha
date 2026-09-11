import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_user.dart';

/// Persists the logged-in AuthUser (including their JWT) on-device, so the
/// app doesn't force a fresh login every time it's reopened.
///
/// We use flutter_secure_storage (backed by Android's EncryptedSharedPreferences
/// / iOS/Windows Keychain-equivalents) instead of shared_preferences here
/// specifically because a JWT is a bearer credential - anyone who reads it
/// can act as this user until it expires, so it deserves encrypted storage,
/// unlike something low-stakes like a theme preference.
///
/// We cache the WHOLE user (not just the token) so the app has something to
/// show immediately on startup without an extra round-trip - GET /api/users/me
/// exists now too (see UserProfileController), but that's for refreshing
/// profile fields the login response doesn't include, not for replacing
/// this cache.
class AuthSessionStorage {
  const AuthSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'auth_session';

  Future<void> save(AuthUser user) {
    return _storage.write(key: _sessionKey, value: jsonEncode(user.toJson()));
  }

  Future<AuthUser?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A session saved by an older build of the app (different AuthUser
      // shape) can't be parsed with today's model. Since this is read on
      // every single request (see ApiClient's auth interceptor), leaving
      // this unhandled would silently break every API call - login
      // included - until the user manually cleared app storage. Treating
      // it as "logged out" instead just sends them back to the login
      // screen, which is what a corrupt/outdated session should do anyway.
      await clear();
      return null;
    }
  }

  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}

// Colocated with the class they build: any feature that needs a Dio client
// or the session storage imports THIS file, not auth's presentation layer.
final _secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final authSessionStorageProvider = Provider<AuthSessionStorage>(
  (ref) => AuthSessionStorage(ref.watch(_secureStorageProvider)),
);
