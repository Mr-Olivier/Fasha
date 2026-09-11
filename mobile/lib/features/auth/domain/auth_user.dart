import 'user_role.dart';

/// The logged-in user, mirroring the backend's AuthResponse DTO. As of the
/// backend's refresh-token rotation work, register/login/refresh all
/// include [phone]/[profileImageUrl] directly - a freshly logged-in
/// session (even on a brand new device) shows the right avatar immediately,
/// instead of only after ProfileScreen loads once.
///
/// We deliberately keep both [token] (short-lived access token) and
/// [refreshToken] as part of this model (rather than storing them
/// separately) so that AuthSessionStorage only has one thing to save/load,
/// and so every screen that needs "who's logged in" (HomeScreen's greeting,
/// ProfileScreen, ...) reads the same single source of truth - see
/// AuthController.applyAccountUpdate for how a profile edit flows back into
/// this cached copy, and ApiClient's interceptor for how [refreshToken]
/// gets traded in for a new pair once [token] expires.
class AuthUser {
  const AuthUser({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.phone,
    this.profileImageUrl,
  });

  final String token;
  final String refreshToken;
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final bool emailVerified;
  final String? phone;
  final String? profileImageUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRoleJson.fromWire(json['role'] as String),
        emailVerified: json['emailVerified'] as bool,
        phone: json['phone'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
        'userId': userId,
        'name': name,
        'email': email,
        'role': role.toWire(),
        'emailVerified': emailVerified,
        'phone': phone,
        'profileImageUrl': profileImageUrl,
      };
}
